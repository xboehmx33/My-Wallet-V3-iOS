// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import DIKit
import FeatureWalletConnectDomain

extension DependencyContainer {

    // MARK: - FeatureWalletConnectData Module

    public static var featureWalletConnectData = module {

        single { WalletConnectService() as WalletConnectServiceAPI }

        single { SessionRepositoryMetadata() as SessionRepositoryAPI }
    }
}
