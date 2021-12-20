// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import SwiftUI

/// Checkbox view.
/// It can be initialized in checked or unchecked state.
///
/// # Figma
///
/// [Checkbox](https://www.figma.com/file/nlSbdUyIxB64qgypxJkm74/03---iOS-%7C-Shared?node-id=6%3A1267)
public struct Checkbox: View {

    @Binding private var isOn: Bool
    private let variant: Variant

    /// Create a checkbox view
    /// - Parameters:
    ///   - isOn: Binding for the checkbox's on/off state
    public init(isOn: Binding<Bool>, variant: Variant = .default) {
        _isOn = isOn
        self.variant = variant
    }

    public var body: some View {
        Toggle(isOn: $isOn) {
            EmptyView()
        }
        .toggleStyle(CheckboxToggleStyle(variant: variant))
    }
}

extension Checkbox {
    public struct Variant {
        let backgroundColor: Color
        let borderColor: Color

        public static let `default` = Self(
            backgroundColor: .semantic.light,
            borderColor: .semantic.medium
        )

        public static let error = Self(
            backgroundColor: Color(light: .palette.red000, dark: .palette.red900),
            borderColor: .semantic.error
        )
    }
}

// MARK: - Private

private struct CheckboxToggleStyle: ToggleStyle {
    let variant: Checkbox.Variant

    func makeBody(configuration: Configuration) -> some View {
        Icon.check
            .accentColor(
                configuration.isOn ? .semantic.background : .clear
            )
            .frame(width: 24, height: 24)
            .onTapGesture { configuration.isOn.toggle() }
            .background(
                RoundedRectangle(cornerRadius: Spacing.buttonBorderRadius)
                    .fill(
                        configuration.isOn ? Color.semantic.primary : variant.backgroundColor
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: Spacing.buttonBorderRadius)
                    .stroke(
                        configuration.isOn ? Color.semantic.primary : variant.borderColor
                    )
            )
    }
}

// MARK: - Previews

struct Checkbox_Previews: PreviewProvider {

    static var previews: some View {
        Group {
            PreviewController(isOn: false, variant: .default)
                .previewLayout(.sizeThatFits)
                .previewDisplayName("Unchecked")

            PreviewController(isOn: true, variant: .default)
                .previewLayout(.sizeThatFits)
                .previewDisplayName("Checked")

            PreviewController(isOn: false, variant: .error)
                .previewLayout(.sizeThatFits)
                .previewDisplayName("Error")
        }
        .padding()
    }

    struct PreviewController: View {
        @State var isOn: Bool
        let variant: Checkbox.Variant

        var body: some View {
            Checkbox(isOn: $isOn, variant: variant)
        }
    }
}
