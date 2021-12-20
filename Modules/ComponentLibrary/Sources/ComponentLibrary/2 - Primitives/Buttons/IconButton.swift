// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import SwiftUI

// MARK: - Public

/// A button displaying an icon. Commonly used as navigation items.
///
/// # Usage
///
///     .primaryNavigation(title: "Title") {
///       IconButton(icon: .qRCode) {
///         openQRCode()
///       }
///     }
///
/// # Figma
///
/// [IconButton](https://www.figma.com/file/nlSbdUyIxB64qgypxJkm74/03---iOS-%7C-Shared?node-id=209%3A1830)
public struct IconButton: View {
    let icon: Icon
    let action: () -> Void

    public init(
        icon: Icon,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            icon
        }
        .buttonStyle(IconButtonStyle())
    }
}

// MARK: - Internal

struct IconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .accentColor(configuration.isPressed ? .semantic.muted.opacity(0.5) : .semantic.muted)
    }
}

// MARK: - Previews

struct IconButton_Previews: PreviewProvider {
    static var previews: some View {
        PreviewContainer()
    }

    struct PreviewContainer: View {
        @State var toggle: Bool = false

        var body: some View {
            PrimaryNavigationView {
                Text(toggle ? "Bar" : "Foo")
                    .primaryNavigation(title: "") { navigationItems }
            }
        }

        @ViewBuilder private var navigationItems: some View {
            IconButton(icon: .qrCode) {
                toggle.toggle()
            }
        }
    }
}
