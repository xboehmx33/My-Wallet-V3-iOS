// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import SwiftUI

/// ExchangeBuyButton from the Figma Component Library.
///
///
/// # Usage:
///
/// `ExchangeBuyButton(title: "Tap me") { print("button did tap") }`
///
/// - Version: 1.0.1
///
/// # Figma
///
///  [Buttons](https://www.figma.com/file/nlSbdUyIxB64qgypxJkm74/03---iOS-%7C-Shared?node-id=3%3A367)

public struct ExchangeBuyButton: View {

    private let title: String
    private let action: () -> Void
    private let isLoading: Bool

    @Environment(\.isEnabled) private var isEnabled

    private let colorCombination = PillButtonStyle.ColorCombination(
        enabled: PillButtonStyle.ColorSet(
            foreground: Color(
                light: .palette.white,
                dark: .palette.white
            ),
            background: .semantic.success,
            border: .semantic.success
        ),
        pressed: PillButtonStyle.ColorSet(
            foreground: .palette.white,
            background: .palette.green600,
            border: .palette.green600
        ),
        disabled: PillButtonStyle.ColorSet(
            foreground: Color(
                light: .palette.white.opacity(0.7),
                dark: .palette.white.opacity(0.4)
            ),
            background: Color(
                light: .palette.green400,
                dark: .palette.green600
            ),
            border: Color(
                light: .palette.green400,
                dark: .palette.green600
            )
        ),
        progressViewRail: .palette.white.opacity(0.8),
        progressViewTrack: .palette.white.opacity(0.25)
    )

    public init(
        title: String,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.isLoading = isLoading
        self.action = action
    }

    public var body: some View {
        Button(title) {
            action()
        }
        .buttonStyle(
            PillButtonStyle(
                isLoading: isLoading,
                isEnabled: isEnabled,
                size: .standard,
                colorCombination: colorCombination
            )
        )
    }
}

struct ExchangeBuyButton_Previews: PreviewProvider {

    static var previews: some View {
        Group {
            ExchangeBuyButton(title: "Enabled", action: {})
                .previewLayout(.sizeThatFits)
                .previewDisplayName("Enabled")

            ExchangeBuyButton(title: "Disabled", action: {})
                .disabled(true)
                .previewLayout(.sizeThatFits)
                .previewDisplayName("Disabled")

            ExchangeBuyButton(title: "Loading", isLoading: true, action: {})
                .previewLayout(.sizeThatFits)
                .previewDisplayName("Loading")
        }
        .padding()
    }
}
