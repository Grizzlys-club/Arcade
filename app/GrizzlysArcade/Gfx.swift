import SpriteKit
import UIKit

/// Cached procedurally drawn textures. Everything is drawn once, so the games stay smooth.
enum Gfx {
    private static var cache: [String: SKTexture] = [:]

    static func texture(_ key: String, size: CGSize, scale: CGFloat = 2, draw: (CGContext) -> Void) -> SKTexture {
        if let t = cache[key] { return t }
        let fmt = UIGraphicsImageRendererFormat()
        fmt.scale = scale
        fmt.opaque = false
        let renderer = UIGraphicsImageRenderer(size: size, format: fmt)
        let img = renderer.image { ctx in draw(ctx.cgContext) }
        let t = SKTexture(image: img)
        t.filteringMode = .linear
        cache[key] = t
        return t
    }

    static func gradientColors(_ top: UIColor, _ bottom: UIColor, in ctx: CGContext, size: CGSize) {
        let space = CGColorSpaceCreateDeviceRGB()
        let cols = [top.cgColor, bottom.cgColor] as CFArray
        if let g = CGGradient(colorsSpace: space, colors: cols, locations: [0, 1]) {
            ctx.drawLinearGradient(g, start: CGPoint(x: 0, y: 0), end: CGPoint(x: 0, y: size.height), options: [])
        }
    }

    static var dot: SKTexture {
        return texture("dot", size: CGSize(width: 16, height: 16)) { ctx in
            ctx.setFillColor(UIColor.white.cgColor)
            ctx.fillEllipse(in: CGRect(x: 0, y: 0, width: 16, height: 16))
        }
    }

    static var glow: SKTexture {
        return texture("glow", size: CGSize(width: 128, height: 128)) { ctx in
            let space = CGColorSpaceCreateDeviceRGB()
            let cols = [UIColor(white: 1, alpha: 0.9).cgColor, UIColor(white: 1, alpha: 0).cgColor] as CFArray
            if let g = CGGradient(colorsSpace: space, colors: cols, locations: [0, 1]) {
                ctx.drawRadialGradient(g, startCenter: CGPoint(x: 64, y: 64), startRadius: 0, endCenter: CGPoint(x: 64, y: 64), endRadius: 64, options: [])
            }
        }
    }

    static var shadow: SKTexture {
        return texture("shadow", size: CGSize(width: 64, height: 24)) { ctx in
            let space = CGColorSpaceCreateDeviceRGB()
            let cols = [UIColor(white: 0, alpha: 0.5).cgColor, UIColor(white: 0, alpha: 0).cgColor] as CFArray
            if let g = CGGradient(colorsSpace: space, colors: cols, locations: [0, 1]) {
                ctx.saveGState()
                ctx.translateBy(x: 32, y: 12)
                ctx.scaleBy(x: 1, y: 0.375)
                ctx.drawRadialGradient(g, startCenter: .zero, startRadius: 0, endCenter: .zero, endRadius: 32, options: [])
                ctx.restoreGState()
            }
        }
    }

    /// Unihockey ball with holes.
    static func ball(_ radius: CGFloat) -> SKTexture {
        let d = radius * 2
        return texture("ball\(Int(radius))", size: CGSize(width: d, height: d), scale: 3) { ctx in
            ctx.setFillColor(UIColor.white.cgColor)
            ctx.fillEllipse(in: CGRect(x: 0.5, y: 0.5, width: d - 1, height: d - 1))
            ctx.setStrokeColor(UIColor(white: 0.55, alpha: 1).cgColor)
            ctx.setLineWidth(max(1, radius * 0.12))
            ctx.strokeEllipse(in: CGRect(x: 0.8, y: 0.8, width: d - 1.6, height: d - 1.6))
            ctx.setFillColor(UIColor(white: 0.45, alpha: 1).cgColor)
            let hr = radius * 0.16
            let c = CGPoint(x: radius, y: radius)
            for i in 0..<8 {
                let a = CGFloat(i) * CGFloat.pi / 4
                let p = CGPoint(x: c.x + cos(a) * radius * 0.58, y: c.y + sin(a) * radius * 0.58)
                ctx.fillEllipse(in: CGRect(x: p.x - hr, y: p.y - hr, width: hr * 2, height: hr * 2))
            }
            ctx.fillEllipse(in: CGRect(x: c.x - hr, y: c.y - hr, width: hr * 2, height: hr * 2))
        }
    }

    static func rect(_ w: CGFloat, _ h: CGFloat, _ color: UIColor, corner: CGFloat = 0) -> SKTexture {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        let key = "rect\(Int(w))x\(Int(h))_\(Int(r * 255))_\(Int(g * 255))_\(Int(b * 255))_\(Int(a * 255))_\(Int(corner))"
        return texture(key, size: CGSize(width: w, height: h)) { ctx in
            ctx.setFillColor(color.cgColor)
            let path = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: w, height: h), cornerRadius: corner)
            ctx.addPath(path.cgPath)
            ctx.fillPath()
        }
    }

    private static func ringKey(_ c: UIColor?) -> String {
        guard let c = c else { return "0" }
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        c.getRed(&r, green: &g, blue: &b, alpha: &a)
        return "\(Int(r * 255))\(Int(g * 255))\(Int(b * 255))\(Int(a * 255))"
    }

    static func circle(_ radius: CGFloat, _ color: UIColor, ring: UIColor? = nil) -> SKTexture {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        let key = "circle\(Int(radius))_\(Int(r * 255))_\(Int(g * 255))_\(Int(b * 255))_\(Int(a * 255))_\(Gfx.ringKey(ring))"
        let d = radius * 2
        return texture(key, size: CGSize(width: d, height: d)) { ctx in
            ctx.setFillColor(color.cgColor)
            ctx.fillEllipse(in: CGRect(x: 1, y: 1, width: d - 2, height: d - 2))
            if let ring = ring {
                ctx.setStrokeColor(ring.cgColor)
                ctx.setLineWidth(max(2, radius * 0.14))
                ctx.strokeEllipse(in: CGRect(x: 2, y: 2, width: d - 4, height: d - 4))
            }
        }
    }

    /// Vertical gradient background of full scene size.
    static func gradient(_ key: String, top: UIColor, bottom: UIColor, size: CGSize = CGSize(width: SW, height: SH)) -> SKTexture {
        return texture("grad_" + key, size: size, scale: 1) { ctx in
            gradientColors(top, bottom, in: ctx, size: size)
        }
    }

    /// Modern portrait backdrop: gradient, faint grid, big logo watermark, vignette.
    static func backdrop(_ key: String, top: UIColor, bottom: UIColor, accent: UIColor, logoAlpha: CGFloat = 0.07) -> SKTexture {
        let size = CGSize(width: SW, height: SH)
        return texture("backdrop_" + key, size: size, scale: 1.5) { ctx in
            gradientColors(top, bottom, in: ctx, size: size)
            ctx.setStrokeColor(accent.withAlphaComponent(0.07).cgColor)
            ctx.setLineWidth(1)
            var x: CGFloat = 0
            while x <= size.width {
                ctx.move(to: CGPoint(x: x, y: 0))
                ctx.addLine(to: CGPoint(x: x, y: size.height))
                x += 30
            }
            var y: CGFloat = 0
            while y <= size.height {
                ctx.move(to: CGPoint(x: 0, y: y))
                ctx.addLine(to: CGPoint(x: size.width, y: y))
                y += 30
            }
            ctx.strokePath()
            if let logo = UIImage(named: "logo") {
                let d: CGFloat = 300
                logo.draw(in: CGRect(x: size.width / 2 - d / 2, y: size.height / 2 - d / 2, width: d, height: d), blendMode: .normal, alpha: logoAlpha)
            }
            let space = CGColorSpaceCreateDeviceRGB()
            let cols = [UIColor(white: 0, alpha: 0).cgColor, UIColor(white: 0, alpha: 0.55).cgColor] as CFArray
            if let g = CGGradient(colorsSpace: space, colors: cols, locations: [0, 1]) {
                ctx.drawRadialGradient(g, startCenter: CGPoint(x: size.width / 2, y: size.height / 2), startRadius: 220, endCenter: CGPoint(x: size.width / 2, y: size.height / 2), endRadius: 560, options: [.drawsAfterEndLocation])
            }
        }
    }

    /// Rounded rectangle with a light top edge and a coloured border (modern button / card look).
    static func pill(_ w: CGFloat, _ h: CGFloat, fill: UIColor, border: UIColor? = nil, corner: CGFloat = 16, gloss: Bool = true) -> SKTexture {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        fill.getRed(&r, green: &g, blue: &b, alpha: &a)
        var br: CGFloat = 0, bg: CGFloat = 0, bb: CGFloat = 0, ba: CGFloat = 0
        (border ?? UIColor.clear).getRed(&br, green: &bg, blue: &bb, alpha: &ba)
        let key = "pill\(Int(w))x\(Int(h))_\(Int(r * 255))_\(Int(g * 255))_\(Int(b * 255))_\(Int(a * 255))_\(Int(br * 255))_\(Int(bg * 255))_\(Int(bb * 255))_\(Int(ba * 255))_\(Int(corner))_\(gloss ? 1 : 0)"
        return texture(key, size: CGSize(width: w, height: h)) { ctx in
            let rect = CGRect(x: 1.5, y: 1.5, width: w - 3, height: h - 3)
            let path = UIBezierPath(roundedRect: rect, cornerRadius: corner)
            ctx.addPath(path.cgPath)
            ctx.setFillColor(fill.cgColor)
            ctx.fillPath()
            // glossy top half
            if gloss {
            ctx.saveGState()
            ctx.addPath(path.cgPath)
            ctx.clip()
            ctx.setFillColor(UIColor(white: 1, alpha: 0.14).cgColor)
            ctx.fill(CGRect(x: 0, y: 0, width: w, height: h * 0.45))
            ctx.restoreGState()
            }
            if let border = border {
                ctx.addPath(path.cgPath)
                ctx.setStrokeColor(border.cgColor)
                ctx.setLineWidth(3)
                ctx.strokePath()
            }
        }
    }

    static func star(_ r: CGFloat, _ color: UIColor) -> SKTexture {
        var rr: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&rr, green: &g, blue: &b, alpha: &a)
        let key = "star\(Int(r))_\(Int(rr * 255))_\(Int(g * 255))_\(Int(b * 255))"
        return texture(key, size: CGSize(width: r * 2, height: r * 2)) { ctx in
            ctx.setFillColor(color.cgColor)
            let c = CGPoint(x: r, y: r)
            for i in 0..<10 {
                let rad = (i % 2 == 0) ? r : r * 0.45
                let ang = CGFloat(i) * CGFloat.pi / 5 - CGFloat.pi / 2
                let p = CGPoint(x: c.x + cos(ang) * rad, y: c.y + sin(ang) * rad)
                if i == 0 { ctx.move(to: p) } else { ctx.addLine(to: p) }
            }
            ctx.closePath()
            ctx.fillPath()
        }
    }

    /// Goal with net, drawn upright: w x h
    static func goal(_ w: CGFloat, _ h: CGFloat) -> SKTexture {
        return texture("goal\(Int(w))x\(Int(h))", size: CGSize(width: w + 16, height: h + 12), scale: 2) { ctx in
            let inner = CGRect(x: 8, y: 8, width: w, height: h)
            ctx.setFillColor(UIColor(white: 0, alpha: 0.45).cgColor)
            ctx.fill(inner)
            ctx.setStrokeColor(UIColor(white: 1, alpha: 0.35).cgColor)
            ctx.setLineWidth(1)
            var x = inner.minX
            while x <= inner.maxX {
                ctx.move(to: CGPoint(x: x, y: inner.minY))
                ctx.addLine(to: CGPoint(x: x, y: inner.maxY))
                x += 10
            }
            var y = inner.minY
            while y <= inner.maxY {
                ctx.move(to: CGPoint(x: inner.minX, y: y))
                ctx.addLine(to: CGPoint(x: inner.maxX, y: y))
                y += 10
            }
            ctx.strokePath()
            ctx.setStrokeColor(UIColor(red: 0.92, green: 0.15, blue: 0.12, alpha: 1).cgColor)
            ctx.setLineWidth(7)
            ctx.setLineCap(.round)
            ctx.move(to: CGPoint(x: inner.minX, y: inner.maxY))
            ctx.addLine(to: CGPoint(x: inner.minX, y: inner.minY))
            ctx.addLine(to: CGPoint(x: inner.maxX, y: inner.minY))
            ctx.addLine(to: CGPoint(x: inner.maxX, y: inner.maxY))
            ctx.strokePath()
        }
    }
}
