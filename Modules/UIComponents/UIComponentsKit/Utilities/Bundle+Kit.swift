// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Foundation
import ToolKit

private class BundleFinder {}
extension Bundle {
    #if canImport(SharedComponentLibrary)
    public static let UIComponents = Bundle.find("Blockchain_UIComponentsKit.bundle", in: BundleFinder.self)
    #else
    public static let UIComponents = Bundle.find("UIComponents_UIComponentsKit.bundle", in: BundleFinder.self)
    #endif
}
