// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import DIKit
import Foundation

extension DependencyContainer {

    // MARK: - MetadataKit Module

    public static var metadataKit = module {

        factory { () -> MetadataServiceAPI in
            MetadataService()
        }
    }
}
