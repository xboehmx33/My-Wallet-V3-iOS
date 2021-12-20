// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import SwiftUI

// MARK: - Public

/// A toggle style switch similar to SwiftUI's `Toggle`
///
/// Note: Unlike SwiftUI's toggle, this animates when the `isOn` binding is changed programatically.
///
/// # Figma
///
/// [PrimarySwitch](https://www.figma.com/file/nlSbdUyIxB64qgypxJkm74/03---iOS-%7C-Shared?node-id=6%3A1273)
public struct PrimarySwitch: View {
    private let variant: Variant
    private let accessibilityLabel: String
    @Binding private var isOn: Bool

    /// Create a PrimarySwitch
    /// - Parameters:
    ///   - variant: Color variant for the switch. Defaults to `.blue`, see `extension PrimarySwitch.Variant` for predefined variants.
    ///   - accessibilityLabel: Hidden label used for accessibility.
    ///   - isOn: Binding for the switch's on/off state
    public init(
        variant: Variant = .blue,
        accessibilityLabel: String,
        isOn: Binding<Bool>
    ) {
        self.variant = variant
        self.accessibilityLabel = accessibilityLabel
        _isOn = isOn
    }

    public var body: some View {
        #if canImport(UIKit)
        Toggle(accessibilityLabel, isOn: $isOn)
            .labelsHidden()
            .toggleStyle(
                PrimarySwitchToggleStyle(onBackgroundColor: variant.onBackgroundColor)
            )
        #else
        Toggle(accessibilityLabel, isOn: $isOn)
            .labelsHidden()
            .toggleStyle(
                SwitchToggleStyle(tint: variant.onBackgroundColor)
            )
        #endif
    }

    /// Color variants for PrimarySwitch
    public struct Variant {
        fileprivate let onBackgroundColor: Color
    }
}

extension PrimarySwitch.Variant {
    public static let blue = PrimarySwitch.Variant(
        onBackgroundColor: Color(
            light: .semantic.primary,
            dark: .semantic.primary
        )
    )

    public static let green = PrimarySwitch.Variant(
        onBackgroundColor: Color(
            light: .palette.green400,
            dark: .palette.green400
        )
    )
}

// MARK: - Private

#if canImport(UIKit)
private struct PrimarySwitchToggleStyle: ToggleStyle {
    let onBackgroundColor: Color

    func makeBody(configuration: Configuration) -> some View {
        UISwitchRepresentable(
            isOn: configuration.$isOn,
            onTintColor: onBackgroundColor,
            thumbTintColor: .semantic.background
        )
    }
}

private struct UISwitchRepresentable: UIViewRepresentable {
    @Binding private var isOn: Bool
    private let onTintColor: Color
    private let thumbTintColor: Color

    init(isOn: Binding<Bool>, onTintColor: Color, thumbTintColor: Color) {
        _isOn = isOn
        self.onTintColor = onTintColor
        self.thumbTintColor = thumbTintColor
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(isOn: $isOn)
    }

    func makeUIView(context: Context) -> UISwitch {
        let view = UISwitch()
        view.onTintColor = UIColor(onTintColor)
        view.thumbTintColor = UIColor(thumbTintColor)
        view.addTarget(context.coordinator, action: #selector(Coordinator.switchDidChange(sender:)), for: .valueChanged)
        return view
    }

    func updateUIView(_ uiView: UISwitch, context: Context) {
        uiView.setOn(isOn, animated: !context.transaction.disablesAnimations)
    }

    @objc class Coordinator: NSObject {
        @Binding var isOn: Bool

        init(isOn: Binding<Bool>) {
            _isOn = isOn
        }

        @objc func switchDidChange(sender: UISwitch) {
            isOn = sender.isOn
        }
    }
}
#endif

// MARK: - Previews

struct PrimarySwitch_Previews: PreviewProvider {
    static var previews: some View {
        Group { // blue, light
            PreviewController(variant: .blue, isOn: true)
                .previewLayout(.sizeThatFits)

            PreviewController(variant: .blue, isOn: false)
                .previewLayout(.sizeThatFits)
        }

        Group { // blue, dark
            PreviewController(variant: .blue, isOn: true)
                .previewLayout(.sizeThatFits)
                .colorScheme(.dark)

            PreviewController(variant: .blue, isOn: false)
                .previewLayout(.sizeThatFits)
                .colorScheme(.dark)
        }

        Group { // green, light
            PreviewController(variant: .green, isOn: true)
                .previewLayout(.sizeThatFits)

            PreviewController(variant: .green, isOn: false)
                .previewLayout(.sizeThatFits)
        }

        Group { // green, dark
            PreviewController(variant: .green, isOn: true)
                .previewLayout(.sizeThatFits)
                .colorScheme(.dark)

            PreviewController(variant: .green, isOn: false)
                .previewLayout(.sizeThatFits)
                .colorScheme(.dark)
        }
    }

    struct PreviewController: View {
        let variant: PrimarySwitch.Variant
        @State var isOn: Bool

        var body: some View {
            PrimarySwitch(
                variant: variant,
                accessibilityLabel: "Test",
                isOn: $isOn
            )
            .background(Color.semantic.background)
        }
    }
}
