// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Foundation
import ToolKit

private class BundleFinder {}

extension Bundle {
    public static let featureWalletConnectUI = Bundle.find(
        "FeatureWalletConnect_FeatureWalletConnectUI.bundle",
        in: BundleFinder.self
    )
}
