// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import SwiftUI

/// Applies font styles from the Figma Component Library.
///
/// See extension below for supported styles.
///
/// # Usage:
///
/// `Text("Hello World!").typography(.title1)`
///
/// - Version: 1.0.1
///
/// # Figma
///
///  [Typography](https://www.figma.com/file/dvXlzvYoDEulsmwkE8iO0i/02---Assets-%7C-Typography?node-id=0%3A1)
public struct Typography: Hashable, Codable {
    public let name: String
    public var size: Length
    var style: TextStyle
    var design: Design = .default
    public var weight: Weight = .bold
}

extension Typography {

    /// Semibold 40pt
    public static let display: Typography = .init(
        name: "Display",
        size: 40.pt,
        style: .largeTitle,
        weight: .semibold
    )

    /// Semibold 32pt
    public static let title1: Typography = .init(
        name: "Title 1",
        size: 32.pt,
        style: .title,
        weight: .semibold
    )

    /// Semibold 24pt
    public static let title2: Typography = .init(
        name: "Title 2",
        size: 24.pt,
        style: .title2,
        weight: .semibold
    )

    /// Semibold 20pt
    public static let title3: Typography = .init(
        name: "Title 3",
        size: 20.pt,
        style: .title3,
        weight: .semibold
    )

    /// Medium 20pt
    public static let subheading: Typography = .init(
        name: "Subheading",
        size: 20.pt,
        style: .subheadline,
        weight: .medium
    )

    /// Medium 16pt, Monospaced with Slashed Zeros
    public static let bodyMono: Typography = .init(
        name: "Body Mono",
        size: 16.pt,
        style: .body,
        design: .monospacedSlashedZero,
        weight: .medium
    )

    /// Medium 16pt
    public static let body1: Typography = .init(
        name: "Body 1",
        size: 16.pt,
        style: .body,
        weight: .medium
    )

    /// Semibold 16pt
    public static let body2: Typography = .init(
        name: "Body 2",
        size: 16.pt,
        style: .body,
        weight: .semibold
    )

    /// Medium 16pt, Monospaced with Slashed Zeros
    public static let paragraphMono: Typography = .init(
        name: "Paragraph Mono",
        size: 16.pt,
        style: .body,
        design: .monospacedSlashedZero,
        weight: .medium
    )

    /// Medium 14pt
    public static let paragraph1: Typography = .init(
        name: "Paragraph 1",
        size: 14.pt,
        style: .body,
        weight: .medium
    )

    /// Semibold 14pt
    public static let paragraph2: Typography = .init(
        name: "Paragraph 2",
        size: 14.pt,
        style: .body,
        weight: .semibold
    )

    /// Medium 12pt
    public static let caption1: Typography = .init(
        name: "Caption 1",
        size: 12.pt,
        style: .caption,
        weight: .medium
    )

    /// Semibold 12pt
    public static let caption2: Typography = .init(
        name: "Caption 2",
        size: 12.pt,
        style: .caption,
        weight: .semibold
    )

    /// Semibold 12pt, Expanded kerning
    ///
    /// Note: The custom kerning on this style only works if the typography is applied directly
    /// to a `Text` view, and does not work in the typical cascading modifier way.
    ///
    /// Note: You must apply `.textCase(.uppercase)` yourself for uppercased text.
    ///
    /// # GOOD, kerning works
    ///     Text("Foo")
    ///       .typography(.overline)
    ///       .textCase(.uppercase)
    ///
    ///  # BAD, kerning breaks
    ///     Text("Foo")
    ///       .textCase(.uppercase)
    ///       .typography(.overline)
    public static let overline: Typography = .init(
        name: "Overline",
        size: 12.pt,
        style: .caption,
        design: .overlineKerning,
        weight: .semibold
    )

    /// Medium 10pt
    public static let micro: Typography = .init(
        name: "Micro (TabBar Text)",
        size: 10.pt,
        style: .caption,
        weight: .medium
    )
}

extension View {

    @ViewBuilder public func typography(_ typography: Typography) -> some View {
        if case .overlineKerning = typography.design {
            modifier(typography)
        } else {
            modifier(typography)
        }
    }

    @ViewBuilder public func typography(_ typography: Typography?) -> some View {
        if let typography = typography {
            self.typography(typography)
        } else {
            self
        }
    }
}

extension Text {

    public func typography(_ typography: Typography) -> Text {
        if case .overlineKerning = typography.design {
            return font(typography.font).kerning(1)
        } else {
            return font(typography.font)
        }
    }

    public func typography(_ typography: Typography?) -> Text {
        if let typography = typography {
            return self.typography(typography)
        } else {
            return self
        }
    }
}

extension Typography {

    public func bold() -> Typography {
        weight(.bold)
    }

    public func semibold() -> Typography {
        weight(.semibold)
    }

    public func medium() -> Typography {
        weight(.medium)
    }

    public func regular() -> Typography {
        weight(.regular)
    }

    func weight(_ weight: Weight) -> Typography {
        var copy = self
        copy.weight = weight
        return copy
    }
}

// swiftlint:disable switch_case_on_newline

extension Typography: ViewModifier {
    var fontName: FontResource {
        switch weight {
        case .regular: return .interRegular
        case .medium: return .interMedium
        case .semibold: return .interSemibold
        case .bold: return .interBold
        }
    }

    var font: Font {
        loadCustomFonts()
        let size = size.in(CGRect.screen)

        #if canImport(UIKit)
        switch design {
        case .default, .serif, .overlineKerning:
            return Font.custom(fontName.rawValue, size: size, relativeTo: style.ui)
        case .monospacedSlashedZero:
            if let uiFont = uiFont {
                return Font(uiFont as CTFont)
            } else {
                return Font.system(size: size, weight: .medium, design: design.ui)
            }
        }
        #else
        return Font.custom(fontName.rawValue, size: size, relativeTo: style.ui)
        #endif
    }

    #if canImport(UIKit)
    var uiFont: UIFont? {
        loadCustomFonts()
        let size = size.in(CGRect.screen)

        guard let descriptor = UIFont(name: fontName.rawValue, size: size)?.fontDescriptor else {
            return nil
        }

        switch design {
        case .default, .serif, .overlineKerning:
            return UIFont(descriptor: descriptor, size: size)
        case .monospacedSlashedZero:
            let settings: [[UIFontDescriptor.FeatureKey: Int]] = [
                [
                    .featureIdentifier: kNumberSpacingType,
                    .typeIdentifier: kMonospacedNumbersSelector
                ],
                [
                    .featureIdentifier: kTypographicExtrasType,
                    .typeIdentifier: kSlashedZeroOnSelector
                ]
            ]
            let monospaced = descriptor.addingAttributes(
                [
                    .featureSettings: settings
                ]
            )
            return UIFont(descriptor: monospaced, size: size)
        }
    }
    #endif

    public func body(content: Content) -> some View {
        content.font(font)
    }
}

extension Typography: CustomStringConvertible, CustomDebugStringConvertible {

    public var description: String { name }
    public var debugDescription: String {
        "\(name) \(size): \(style) \(design) \(weight)"
    }
}

extension Typography {

    public enum TextStyle: String, Codable, Hashable {

        case largeTitle
        case title
        case title2
        case title3
        case headline
        case subheadline
        case body
        case callout
        case footnote
        case caption
        case caption2

        public var ui: Font.TextStyle {
            switch self {
            case .largeTitle: return .largeTitle
            case .title: return .title
            case .title2: return .title2
            case .title3: return .title3
            case .headline: return .headline
            case .subheadline: return .subheadline
            case .body: return .body
            case .callout: return .callout
            case .footnote: return .footnote
            case .caption: return .caption
            case .caption2: return .caption2
            }
        }
    }

    public enum FontResource: String, Hashable, Codable, CaseIterable {
        case interRegular = "Inter-Regular"
        case interMedium = "Inter-Medium"
        case interSemibold = "Inter-SemiBold"
        case interBold = "Inter-Bold"
    }

    public enum Weight: String, Hashable, Codable, CaseIterable {
        case regular
        case medium
        case semibold
        case bold
    }

    public enum Design: String, Codable, Hashable {

        case `default`
        case serif
        case monospacedSlashedZero
        case overlineKerning

        public var ui: Font.Design {
            switch self {
            case .default: return .default
            case .serif: return .serif
            case .monospacedSlashedZero: return .monospaced
            case .overlineKerning: return .default
            }
        }

        var isOverlineKerning: Bool {
            switch self {
            case .overlineKerning: return true
            default: return false
            }
        }
    }

    public static let allTypography: [Typography] = [
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
        .overline,
        .micro
    ]
}

struct Typography_Previews: PreviewProvider {

    static func previewText(for typography: Typography) -> String {
        switch typography {
        case .bodyMono, .paragraphMono:
            return "0123456789"
        default:
            return "The quick brown fox jumps over the lazy dog"
        }
    }

    static var previews: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ForEach(Typography.allTypography, id: \.self) { typography in

                    Text(typography.name)
                        .typography(typography)
                        .if(typography.design.isOverlineKerning) {
                            $0.textCase(.uppercase)
                        }

                    Text("\(typography.weight.rawValue) \(typography.size.description)")
                        .typography(.caption1.weight(typography.weight))

                    Text(previewText(for: typography))
                        .typography(typography)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                        .if(typography.design.isOverlineKerning) {
                            $0.textCase(.uppercase)
                        }

                    Divider()
                }
            }
            .padding()
        }
    }
}
