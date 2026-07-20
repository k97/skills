#!/usr/bin/env bash
# redirect-trace.sh — trace live redirect chains; detect loops and split hosts.
#
# Redirect loops are invisible from source. They emerge when an app-level host
# redirect fights one the hosting platform already performs, so only a live
# trace finds them. Loops often appear on deep paths but not on "/", so pass
# the routes you actually care about.
#
# Usage:   redirect-trace.sh <domain-or-url> [path ...]
# Example: redirect-trace.sh example.com /blog /pricing
#
# Env:     MAX_REDIRS (default 10)   UA (default a generic browser string)
# Exit:    0 clean · 1 loop, dead URL, or split host · 2 usage error

set -uo pipefail

MAX_REDIRS=${MAX_REDIRS:-10}
UA=${UA:-"Mozilla/5.0 (compatible; discoverability/1.0)"}

if [ $# -lt 1 ]; then
  sed -n '3,13p' "$0" >&2
  exit 2
fi

raw=$1
shift
host=${raw#*://}
host=${host%%/*}
apex=${host#www.}
if [ -z "$apex" ]; then
  echo "redirect-trace: could not parse a host from '$raw'" >&2
  exit 2
fi

# http:// probes the http→https upgrade; both hosts probe canonicalisation.
urls=("http://$apex/" "https://$apex/" "https://www.$apex/")
for p in "$@"; do
  case $p in
    /*) ;;
    *) p=/$p ;;
  esac
  urls+=("https://$apex$p" "https://www.$apex$p")
done

loops=0
dead=0
notok=0
landed=()

for u in "${urls[@]}"; do
  hdrs=$(curl -sS -A "$UA" -o /dev/null -D - -L --max-redirs "$MAX_REDIRS" \
    -w '__FINAL__ %{http_code} %{num_redirects} %{url_effective}\n' \
    "$u" 2>/dev/null)
  rc=$?

  printf '\n== %s\n' "$u"

  code=''
  seen=''
  repeat=''
  while IFS= read -r line; do
    line=${line%$'\r'}
    case $line in
      HTTP/*)
        code=${line#* }
        code=${code%% *}
        ;;
      [Ll]ocation:*)
        loc=${line#*:}
        loc=${loc# }
        printf '   %s -> %s\n' "${code:-???}" "$loc"
        lh=${loc#*://}
        lh=${lh%%/*}
        case " $seen " in
          *" $lh "*) repeat=$lh ;;
        esac
        seen="$seen $lh"
        ;;
    esac
  done < <(printf '%s\n' "$hdrs")

  if [ "$rc" -eq 47 ]; then
    printf '   CRITICAL  redirect loop — exceeded %s hops. This URL is down for users.\n' "$MAX_REDIRS"
    if [ -n "$repeat" ]; then
      printf '   hosts ping-ponging: %s\n' "$(printf '%s\n' $seen | sort -u | tr '\n' ' ')"
    fi
    printf '   Fix: remove the APP-level host redirect, not add another. The platform\n'
    printf '        already canonicalises this host.\n'
    loops=$((loops + 1))
    continue
  fi

  final=$(printf '%s\n' "$hdrs" | sed -n 's/^__FINAL__ //p' | tail -1)
  read -r fcode fhops furl <<<"${final:-}"

  if [ -z "${furl:-}" ]; then
    printf '   ERROR  no response (curl exit %s)\n' "$rc"
    dead=$((dead + 1))
    continue
  fi

  fhost=${furl#*://}
  fhost=${fhost%%/*}

  if [ "${fcode:-0}" -ge 400 ] 2>/dev/null; then
    printf '   %s hops -> HTTP %s  %s   <-- HIGH: not indexable\n' "$fhops" "$fcode" "$furl"
    notok=$((notok + 1))
  else
    printf '   %s hops -> HTTP %s  %s\n' "$fhops" "$fcode" "$furl"
  fi
  landed+=("$fhost")
done

echo
echo "== summary"

[ "$loops" -gt 0 ] && echo "CRITICAL  $loops URL(s) loop. Those pages are down for real users."
[ "$dead" -gt 0 ] && echo "ERROR     $dead URL(s) returned no response (DNS or TLS failure)."
[ "$notok" -gt 0 ] && echo "HIGH      $notok URL(s) ended non-2xx and cannot be indexed."

if [ ${#landed[@]} -eq 0 ]; then
  exit 1
fi

hosts=$(printf '%s\n' "${landed[@]}" | sort -u)
count=$(printf '%s\n' "$hosts" | wc -l | tr -d ' ')

if [ "$count" -gt 1 ]; then
  echo "HIGH  requests land on more than one host — ranking signals are split:"
  printf '%s\n' "$hosts" | sed 's/^/    /'
  echo "  Pick ONE canonical host, then align every canonical, sitemap <loc>,"
  echo "  robots.txt Host:/Sitemap:, and og:url to it."
else
  echo "canonical host (observed): $hosts"
  echo "Every <link rel=canonical>, sitemap <loc>, robots.txt Host:/Sitemap:, and"
  echo "og:url must use this exact host. Verify with audit-meta.mjs."
fi

if [ "$loops" -gt 0 ] || [ "$dead" -gt 0 ] || [ "$notok" -gt 0 ] || [ "$count" -gt 1 ]; then
  exit 1
fi
exit 0
