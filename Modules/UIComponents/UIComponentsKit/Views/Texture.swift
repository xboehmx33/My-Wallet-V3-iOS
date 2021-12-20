// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import CasePaths
#if canImport(SharedComponentLibrary)
import SharedComponentLibrary
#else
import ComponentLibrary
#endif
import SwiftUI

extension View {

    /// Apply a foreground color to the view
    public func foregroundTexture(_ color: Color) -> some View {
        modifier(TextureModifier(texture: color.texture, space: .foreground))
    }

    /// Apply a foreground gradient to the view
    /// this will mask the gradient with the contents of the view
    public func foregroundTexture(
        linear gradient: Gradient,
        startPoint: UnitPoint = .leading,
        endPoint: UnitPoint = .trailing
    ) -> some View {
        modifier(
            TextureModifier(
                texture: gradient.linearTexture(start: startPoint, end: endPoint),
                space: .foreground
            )
        )
    }

    /// Apply a foreground texture to the view
    public func foregroundTexture(_ texture: Texture) -> some View {
        modifier(TextureModifier(texture: texture, space: .foreground))
    }

    /// Apply an optional foreground texture to the view
    /// if no texture is available the original view will be left untouched
    @ViewBuilder public func foregroundTexture(_ texture: Texture?) -> some View {
        if let texture = texture {
            modifier(TextureModifier(texture: texture, space: .foreground))
        } else {
            self
        }
    }

    /// Apply a background color to the view
    public func backgroundTexture(_ color: Color) -> some View {
        modifier(TextureModifier(texture: color.texture, space: .background))
    }

    /// Apply a background gradient to the view
    public func backgroundTexture(
        linear gradient: Gradient,
        startPoint: UnitPoint = .leading,
        endPoint: UnitPoint = .trailing
    ) -> some View {
        modifier(
            TextureModifier(
                texture: gradient.linearTexture(start: startPoint, end: endPoint),
                space: .background
            )
        )
    }

    /// Apply a background texture to the view
    public func backgroundTexture(_ texture: Texture) -> some View {
        modifier(TextureModifier(texture: texture, space: .background))
    }

    /// Apply a background color to the view
    /// if no texture is available the original view will be left untouched
    @ViewBuilder public func backgroundTexture(_ texture: Texture?) -> some View {
        if let texture = texture {
            modifier(TextureModifier(texture: texture, space: .background))
        } else {
            self
        }
    }
}

public struct Texture: Codable, Hashable {
    public var color: Color?
    public var gradient: Gradient?
}

extension Texture {

    public enum Color: Codable, Hashable {
        case rgb(r: Double, g: Double, b: Double, a: Double)
        case hsb(h: Double, s: Double, b: Double, a: Double)
    }

    public struct Gradient: Codable, Hashable {

        public struct Stop: Codable, Hashable {
            public var color: Color
            public var location: CGFloat
        }

        public struct Linear: Codable, Hashable {
            public var start: [CGFloat]
            public var end: [CGFloat]
        }

        public var stops: [Stop]
        public var linear: Linear?
    }
}

extension Texture.Color {

    public enum Key: String, CodingKey {
        case rgb
        case hsb
    }

    private typealias Case = CasePath<Texture.Color, (Double, Double, Double, Double)>

    private static var __allCases: [Key: Case] = [
        Key.rgb: /Texture.Color.rgb,
        Key.hsb: /Texture.Color.hsb
    ]

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Key.self)
        for (key, casePath) in Self.__allCases {
            var nested = try container.nestedUnkeyedContainer(forKey: key)
            self = try casePath.embed(
                (
                    nested.decode(Double.self),
                    nested.decode(Double.self),
                    nested.decode(Double.self),
                    nested.decode(Double.self)
                )
            )
            return
        }
        throw DecodingError.valueNotFound(
            Self.self,
            .init(
                codingPath: decoder.codingPath,
                debugDescription: "No color was found at codingPath '\(decoder.codingPath)'"
            )
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Key.self)
        for (key, casePath) in Self.__allCases {
            if let o = casePath.extract(from: self) {
                var nested = container.nestedUnkeyedContainer(forKey: key)
                try nested.encode(o.0)
                try nested.encode(o.1)
                try nested.encode(o.2)
                try nested.encode(o.3)
                return
            }
        }
    }
}

struct TextureModifier: ViewModifier {

    enum Space {
        case foreground
        case background
    }

    let texture: Texture
    let space: Space

    func body(content: Content) -> some View {
        switch space {
        case .foreground:
            if let color = texture.color {
                content.foregroundColor(.init(color))
            } else if let gradient = texture.gradient, let linearGradient = LinearGradient(gradient) {
                content
                    .foregroundColor(.clear)
                    .overlay(linearGradient.mask(content))
            } else {
                content
            }
        case .background:
            if let color = texture.color {
                content.background(SwiftUI.Color(color))
            } else if let gradient = texture.gradient, let linearGradient = LinearGradient(gradient) {
                content.background(linearGradient)
            } else {
                content
            }
        }
    }
}

extension Color {

    #if canImport(UIKit)
    private typealias Native = UIColor
    #elseif canImport(AppKit)
    private typealias Native = NSColor
    #endif

    // swiftlint:disable:next large_tuple
    private var hsba: (hue: Double, saturation: Double, brightness: Double, alpha: Double) {
        var (h, s, b, a): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
        guard Native(self).getHue(&h, saturation: &s, brightness: &b, alpha: &a) else {
            return (0, 0, 0, 0)
        }
        return (h.d, s.d, b.d, a.d)
    }

    // swiftlint:disable:next large_tuple
    private var rgba: (red: Double, green: Double, blue: Double, alpha: Double) {
        var (r, g, b, a): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
        guard Native(self).getRed(&r, green: &g, blue: &b, alpha: &a) else {
            return (0, 0, 0, 0)
        }
        return (r.d, g.d, b.d, a.d)
    }

    public var rgbTexture: Texture {
        let (r, g, b, a) = rgba
        return .init(color: .rgb(r: r, g: g, b: b, a: a))
    }

    public var hsbTexture: Texture {
        let (h, s, b, a) = hsba
        return .init(color: .hsb(h: h, s: s, b: b, a: a))
    }

    public var texture: Texture { hsbTexture }

    public init?(_ texture: Texture, colorSpace: Color.RGBColorSpace = .sRGB) {
        if let color = texture.color {
            self.init(color, colorSpace: colorSpace)
        } else if let color = texture.gradient?.stops.first?.color {
            self.init(color, colorSpace: colorSpace)
        } else {
            return nil
        }
    }

    public init(_ color: Texture.Color, colorSpace: Color.RGBColorSpace = .sRGB) {
        switch color {
        case .hsb(let h, let s, let b, let a):
            self.init(hue: h, saturation: s, brightness: b, opacity: a)
        case .rgb(let r, let g, let b, let a):
            self.init(colorSpace, red: r, green: g, blue: b, opacity: a)
        }
    }
}

extension Gradient {

    public func linearTexture(start: UnitPoint, end: UnitPoint) -> Texture {
        .init(
            gradient: .init(
                stops: stops.map { stop in
                    Texture.Gradient.Stop(
                        color: stop.color.texture.color!,
                        location: stop.location
                    )
                },
                linear: .init(start: [start.x, start.y], end: [end.x, end.y])
            )
        )
    }

    public init?(_ texture: Texture, colorSpace: Color.RGBColorSpace = .sRGB) {
        if let gradient = texture.gradient {
            self.init(gradient, colorSpace: colorSpace)
        } else if let color = texture.color {
            self.init(
                stops: [
                    Stop(color: Color(color, colorSpace: colorSpace), location: 0),
                    Stop(color: Color(color, colorSpace: colorSpace), location: 1)
                ]
            )
        } else {
            return nil
        }
    }

    public init(_ gradient: Texture.Gradient, colorSpace: Color.RGBColorSpace = .sRGB) {
        self.init(
            stops: gradient.stops.map { stop in
                Stop(
                    color: Color(stop.color, colorSpace: colorSpace),
                    location: stop.location
                )
            }
        )
    }
}

extension LinearGradient {

    public init?(_ gradient: Texture.Gradient) {
        guard
            let linear = gradient.linear,
            let start = UnitPoint(linear.start),
            let end = UnitPoint(linear.end)
        else {
            return nil
        }
        self.init(gradient: Gradient(gradient), startPoint: start, endPoint: end)
    }
}

extension UnitPoint {

    fileprivate init?(_ xy: [CGFloat]) {
        guard xy.count == 2 else { return nil }
        self.init(x: xy[0], y: xy[1])
    }
}

#if DEBUG
struct Texture_Previews: PreviewProvider {

    static let allTypography: [Typography] = [
        .display,
        .title1,
        .title2,
        .title3,
        .subheading,
        .bodyMono,
        .body1,
        .body2,
        .paragraphMono,
        .paragraph1,
        .paragraph2,
        .caption1,
        .caption2,
        .overline
    ]

    static var previews: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Rectangle()
                    .frame(height: 100)
                    .foregroundTexture(
                        linear: Gradient(
                            colors: [
                                Color(paletteColor: .red200),
                                Color(paletteColor: .blue300)
                            ]
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .overlay(
                        Text("Red 200 -> Blue 300")
                            .padding()
                            .typography(.display)
                            .scaledToFit()
                            .minimumScaleFactor(0.5)
                            .foregroundColor(.white)
                    )
                Rectangle()
                    .frame(height: 100)
                    .foregroundColor(.clear)
                    .backgroundTexture(Color(paletteColor: .orange200))
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .overlay(
                        Text("Orange 200")
                            .padding()
                            .typography(.display)
                            .foregroundTexture(
                                linear: Gradient(
                                    colors: [
                                        Color(paletteColor: .orange600),
                                        Color(paletteColor: .orange800)
                                    ]
                                )
                            )
                    )
                ForEach(allTypography, id: \.self) { typography in
                    Text("The quick brown fox jumps over the lazy dog")
                        .typography(typography)
                        .foregroundTexture(
                            linear: Gradient(
                                colors: [
                                    Color(paletteColor: .blue400),
                                    Color(paletteColor: .blue500),
                                    Color(paletteColor: .blue600),
                                    Color(paletteColor: .blue700),
                                    Color(paletteColor: .blue800),
                                    Color(paletteColor: .blue900)
                                ]
                            )
                        )
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                }
            }
            .padding()
        }
    }
}
#endif
