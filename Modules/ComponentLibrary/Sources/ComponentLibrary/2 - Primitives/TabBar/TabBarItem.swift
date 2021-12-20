// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import SwiftUI

extension View {

    /// Assigns a tab bar item to the view for use in `TabBar`
    /// - Parameter item: The item for the given view
    /// - Returns: The same view
    public func tabBarItem(_ item: TabBarItem) -> some View {
        modifier(TabBarItemModifier(item: item))
    }
}

/// A type for describing an element in `TabBarView`
public enum TabBarItem {

    /// A selectable button with an icon and label
    case tab(identifier: AnyHashable, icon: Icon, title: String)

    /// A selectable button that switches between +/x
    case fab(identifier: AnyHashable, isActive: Binding<Bool>, isPulsing: Bool)
}

/// Identifiable for use in SwiftUI `ForEach`
extension TabBarItem: Identifiable {

    public var id: AnyHashable {
        switch self {
        case .tab(let identifier, _, _):
            return identifier
        case .fab(let identifier, _, _):
            return identifier
        }
    }
}

// Equatable for use in Preference Keys
extension TabBarItem: Equatable {
    public static func == (lhs: TabBarItem, rhs: TabBarItem) -> Bool {
        switch (lhs, rhs) {
        case (.tab(let lhsIdentifier, let lhsIcon, let lhsTitle), .tab(let rhsIdentifier, let rhsIcon, let rhsTitle)):
            return lhsIdentifier == rhsIdentifier && lhsIcon == rhsIcon && lhsTitle == rhsTitle
        case (.fab(let lhsIdentifier, _, _), .fab(let rhsIdentifier, _, _)):
            return lhsIdentifier == rhsIdentifier
        default:
            return false
        }
    }
}

extension TabBarItem {

    /// Helper for precondition of only one FAB in tab bar
    var isFab: Bool {
        switch self {
        case .tab:
            return false
        case .fab:
            return true
        }
    }
}
