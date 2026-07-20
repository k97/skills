// appicon.swift — dependency-free image operations for Apple app icon generation.
// Runs with the Swift bundled in Xcode Command Line Tools: `swift appicon.swift ...`
//
// Modes:
//   resize  <in> <out> <size>              exact square resize (validate squareness first)
//   flatten <in> <out> <size> [#RRGGBB]    resize + composite on opaque colour, alpha STRIPPED
//                                          (App Store marketing icons must have no alpha)
//   pad     <in> <out>                     square-ify by centring on a transparent canvas
//   macos   <in> <out> [--size N] [--no-shadow]
//           Apple macOS icon-grid treatment for legacy .icns: content scaled into an
//           824/1024 rounded-rect (r ≈ 185.4/1024, circular approximation of Apple's
//           squircle), centred with margins, subtle drop shadow like Apple's template.
//
// All output is 8-bit sRGB PNG. Prints the written path on success.

import Foundation
import CoreGraphics
import ImageIO

func fail(_ msg: String) -> Never {
    FileHandle.standardError.write(Data("error: \(msg)\n".utf8))
    exit(1)
}

func load(_ path: String) -> CGImage {
    guard let src = CGImageSourceCreateWithURL(URL(fileURLWithPath: path) as CFURL, nil),
          let img = CGImageSourceCreateImageAtIndex(src, 0, nil)
    else { fail("cannot read image at \(path)") }
    return img
}

func makeContext(_ size: Int, opaque: Bool = false) -> CGContext {
    let alphaInfo: CGImageAlphaInfo = opaque ? .noneSkipLast : .premultipliedLast
    guard let ctx = CGContext(data: nil, width: size, height: size,
                              bitsPerComponent: 8, bytesPerRow: 0,
                              space: CGColorSpace(name: CGColorSpace.sRGB)!,
                              bitmapInfo: alphaInfo.rawValue)
    else { fail("cannot create \(size)x\(size) canvas") }
    ctx.interpolationQuality = .high
    return ctx
}

func write(_ ctx: CGContext, to path: String) {
    guard let img = ctx.makeImage(),
          let dst = CGImageDestinationCreateWithURL(URL(fileURLWithPath: path) as CFURL,
                                                    "public.png" as CFString, 1, nil)
    else { fail("cannot create output at \(path)") }
    CGImageDestinationAddImage(dst, img, nil)
    guard CGImageDestinationFinalize(dst) else { fail("failed writing \(path)") }
    print(path)
}

func parseColor(_ hex: String) -> CGColor {
    var s = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
    if s.count == 3 { s = s.map { "\($0)\($0)" }.joined() }
    guard s.count == 6, let v = UInt32(s, radix: 16) else { fail("bad colour '\(hex)', expected #RRGGBB") }
    return CGColor(srgbRed: CGFloat((v >> 16) & 0xFF) / 255,
                   green: CGFloat((v >> 8) & 0xFF) / 255,
                   blue: CGFloat(v & 0xFF) / 255, alpha: 1)
}

let args = CommandLine.arguments
guard args.count >= 4 else {
    fail("usage: appicon.swift <resize|flatten|pad|macos> <in> <out> [options]")
}
let mode = args[1], input = args[2], output = args[3]
let img = load(input)

switch mode {
case "resize":
    guard args.count >= 5, let size = Int(args[4]), size > 0 else { fail("resize needs <size>") }
    let ctx = makeContext(size)
    ctx.draw(img, in: CGRect(x: 0, y: 0, width: size, height: size))
    write(ctx, to: output)

case "flatten":
    guard args.count >= 5, let size = Int(args[4]), size > 0 else { fail("flatten needs <size> [#RRGGBB]") }
    let ctx = makeContext(size, opaque: true)
    ctx.setFillColor(parseColor(args.count >= 6 ? args[5] : "#FFFFFF"))
    ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))
    ctx.draw(img, in: CGRect(x: 0, y: 0, width: size, height: size))
    write(ctx, to: output)

case "pad":
    let side = max(img.width, img.height)
    let ctx = makeContext(side)
    ctx.draw(img, in: CGRect(x: (side - img.width) / 2, y: (side - img.height) / 2,
                             width: img.width, height: img.height))
    write(ctx, to: output)

case "macos":
    var canvas = 1024
    var shadow = true
    var i = 4
    while i < args.count {
        switch args[i] {
        case "--size":
            i += 1
            guard i < args.count, let n = Int(args[i]), n > 0 else { fail("--size needs a number") }
            canvas = n
        case "--no-shadow":
            shadow = false
        default:
            fail("unknown option '\(args[i])' for macos mode")
        }
        i += 1
    }

    let c = CGFloat(canvas)
    let box = (c * 824.0 / 1024.0).rounded()      // Apple template: 824px content box on a 1024 canvas
    let radius = c * 185.4 / 1024.0               // ≈ Apple's corner radius at that scale
    let inset = ((c - box) / 2).rounded()
    let rect = CGRect(x: inset, y: inset, width: box, height: box)

    let maskCtx = makeContext(canvas)
    maskCtx.addPath(CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil))
    maskCtx.clip()
    maskCtx.draw(img, in: rect)
    guard let masked = maskCtx.makeImage() else { fail("masking failed") }

    let ctx = makeContext(canvas)
    if shadow {
        // Approximates the shadow baked into Apple's Big Sur design template
        // (negative y = downward in CG's flipped-to-visual terms).
        ctx.setShadow(offset: CGSize(width: 0, height: -c * 0.01), blur: c * 0.02,
                      color: CGColor(gray: 0, alpha: 0.3))
    }
    ctx.draw(masked, in: CGRect(x: 0, y: 0, width: c, height: c))
    write(ctx, to: output)

default:
    fail("unknown mode '\(mode)' — expected resize|flatten|pad|macos")
}
