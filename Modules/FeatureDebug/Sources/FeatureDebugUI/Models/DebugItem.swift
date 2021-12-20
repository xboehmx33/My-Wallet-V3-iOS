// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Foundation

enum DebugItemType: CaseIterable {
    case interalFeatureFlags
    case componentLibraryExamples
    case colorScheme
}

extension DebugItemType {
    var title: String {
        switch self {
        case .interalFeatureFlags:
            return "Internal Feature Flags"
        case .componentLibraryExamples:
            return "Component Library Examples"
        case .colorScheme:
            return "Switch Color Scheme (Light/Dark)"
        }
    }

    static func provideAllItems() -> [DebugItem] {
        DebugItemType.allCases.map(DebugItem.init(type:))
    }
}

struct DebugItem: Equatable {
    let title: String
    let type: DebugItemType

    init(type: DebugItemType) {
        title = type.title
        self.type = type
    }
}
