// Copyright © Blockchain Luxembourg S.A. All rights reserved.

#if canImport(SharedComponentLibrary)
import SharedComponentLibrary
#else
import ComponentLibrary
#endif
import SwiftUI

/// A simple template for any `View` that features some content followed by a number of buttons at the end.
/// - NOTE:Having buttons at the end is optional and they can be omitted. If omitted, no button is rendered and the content takes 100% of the view.
public struct ActionableView<Content: View>: View {

    /// Represents a `LoadingButton` in the Design System
    public struct ButtonState: Hashable {
        public enum Style: Hashable {
            case primary, secondary
        }

        public let title: String
        public let action: () -> Void
        public let style: Style
        public let loading: Bool
        public let enabled: Bool

        public init(
            title: String,
            action: @escaping () -> Void,
            style: Style = .primary,
            loading: Bool = false,
            enabled: Bool = true
        ) {
            self.title = title
            self.action = action
            self.style = style
            self.loading = loading
            self.enabled = enabled
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(title)
            hasher.combine(style)
        }

        public static func == (lhs: ButtonState, rhs: ButtonState) -> Bool {
            lhs.title == rhs.title && lhs.style == rhs.style && lhs.loading == rhs.loading
        }
    }

    public let content: () -> Content
    public let buttons: [ButtonState]

    public init(buttons: [ButtonState] = [], @ViewBuilder content: @escaping () -> Content) {
        self.buttons = buttons
        self.content = content
    }

    public var body: some View {
        VStack(alignment: .center) {
            content()
            VStack(spacing: LayoutConstants.VerticalSpacing.withinButtonsGroup) {
                ForEach(buttons, id: \.title) { button in
                    switch button.style {
                    case .primary:
                        UIComponentsKit.PrimaryButton(
                            title: button.title,
                            action: button.action,
                            loading: .constant(button.loading)
                        )
                        .disabled(!button.enabled)
                        .frame(maxWidth: .infinity)
                    case .secondary:
                        UIComponentsKit.SecondaryButton(
                            title: button.title,
                            action: button.action,
                            loading: .constant(button.loading)
                        )
                        .disabled(!button.enabled)
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .padding()
    }
}

extension ActionableView where Content == AnyView {

    public init<Image: View>(
        @ViewBuilder image: @escaping () -> Image,
        title: String,
        message: String,
        buttons: [ButtonState] = [],
        imageSpacing: CGFloat = LayoutConstants.VerticalSpacing.betweenContentGroups
    ) {
        self.init(buttons: buttons) {
            AnyView(
                VStack(alignment: .center, spacing: imageSpacing) {
                    Spacer()
                    image()
                    VStack {
                        RichText(title)
                            .textStyle(.title)
                        RichText(message)
                            .textStyle(.body)
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
                .background(Color.viewPrimaryBackground)
            )
        }
    }
}

extension ActionableView where Content == TupleView<(Spacer, InfoView, Spacer)> {

    public init(_ model: InfoView.Model, buttons: [ButtonState] = [], in bundle: Bundle = .main) {
        self.init(buttons: buttons) {
            Spacer()
            InfoView(model, in: bundle)
            Spacer()
        }
    }
}

#if DEBUG
// swiftlint:disable line_length
struct ActionableView_Previews: PreviewProvider {
    static var previews: some View {
        ActionableView(
            image: {
                Image(systemName: "applelogo")
                    .font(.largeTitle)
                    .imageScale(.large)
                    .foregroundColor(.black)
            },
            title: "Lorem Ipsum",
            message: "Lorem ipsum **dolor** sit amet, consectetur adipiscing **elit**. Nulla sit amet mi sodales, egestas nulla eu, tincidunt est.",
            buttons: [
                .init(
                    title: "Primary",
                    action: {},
                    style: .primary
                ),
                .init(
                    title: "Secondary",
                    action: {},
                    style: .secondary
                )
            ]
        )

        ActionableView(
            image: {
                Image(systemName: "applelogo")
                    .font(.largeTitle)
                    .imageScale(.large)
                    .foregroundColor(.black)
            },
            title: "Lorem Ipsum",
            message: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nulla sit amet mi sodales, egestas nulla eu, tincidunt est.",
            buttons: [
                .init(
                    title: "Primary",
                    action: {},
                    style: .primary,
                    loading: true
                ),
                .init(
                    title: "Secondary",
                    action: {},
                    style: .secondary
                )
            ]
        )

        ActionableView(
            image: {
                Image(systemName: "applelogo")
                    .font(.largeTitle)
                    .imageScale(.large)
                    .foregroundColor(.black)
            },
            title: "Lorem Ipsum",
            message: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nulla sit amet mi sodales, egestas nulla eu, tincidunt est.",
            buttons: [
                .init(
                    title: "Primary",
                    action: {},
                    style: .primary,
                    enabled: false
                )
            ]
        )

        ActionableView(
            image: {
                Image(systemName: "applelogo")
                    .font(.largeTitle)
                    .imageScale(.large)
                    .foregroundColor(.black)
            },
            title: "Lorem Ipsum",
            message: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nulla sit amet mi sodales, egestas nulla eu, tincidunt est."
        )

        ActionableView(
            .init(
                media: .image(systemName: "applelogo"),
                title: "Lorem Ipsum",
                subtitle: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nulla sit amet mi sodales, egestas nulla eu, tincidunt est."
            ),
            buttons: [
                .init(
                    title: "Primary",
                    action: {},
                    style: .primary,
                    enabled: false
                )
            ]
        )
    }
}
#endif
