// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Foundation

private class BundleFinder {}

extension Bundle {
    #if canImport(SharedComponentLibrary)
    public static let componentLibrary = Bundle.find("Blockchain_SharedComponentLibrary.bundle", in: BundleFinder.self)
    #else
    public static let componentLibrary = Bundle.find("ComponentLibrary_ComponentLibrary.bundle", in: BundleFinder.self)
    #endif
}

// The following is copied from `ToolKit` to avoid adding an extra external dependency into the Exchange app
extension Bundle {

    /// Returns the resource bundle associated with a Swift module.
    private static func find(_ bundleName: String, in type: AnyObject.Type) -> Bundle {

        let candidates = [
            // Bundle should be present here when the package is linked into an App.
            Bundle.main.resourceURL,

            // Bundle should be present here when the package is linked into a framework.
            Bundle(for: type).resourceURL,

            // For command-line tools.
            Bundle.main.bundleURL,

            // For SwiftUI previews
            Bundle(for: type).resourceURL?
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .deletingLastPathComponent(),

            Bundle(for: type).resourceURL?
                .deletingLastPathComponent()
                .deletingLastPathComponent()
        ]

        for candidate in candidates {
            let bundlePath = candidate?.appendingPathComponent(bundleName)
            if let bundle = bundlePath.flatMap(Bundle.init(url:)) {
                return bundle
            }
        }

        fatalError("unable to find bundle named \(bundleName)")
    }
}
