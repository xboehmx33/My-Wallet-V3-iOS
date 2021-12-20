// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import DIKit
import Foundation
import ToolKit

public protocol SupportedAssetsFilePathProviderAPI {
    var remoteERC20Assets: URL? { get }
    var localERC20Assets: URL? { get }
    var remoteCustodialAssets: URL? { get }
    var localCustodialAssets: URL? { get }
}

final class SupportedAssetsFilePathProvider: SupportedAssetsFilePathProviderAPI {

    private enum FileName {
        enum Local {
            static var erc20: String { "local-currencies-erc20.json" }
            static var custodial: String { "local-currencies-custodial.json" }
        }

        enum Remote {
            static var erc20: String { "remote-currencies-erc20.json" }
            static var custodial: String { "remote-currencies-custodial.json" }
        }
    }

    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    var localERC20Assets: URL? {
        Bundle.module.url(forResource: FileName.Local.erc20, withExtension: nil)
    }

    var localCustodialAssets: URL? {
        Bundle.module.url(forResource: FileName.Local.custodial, withExtension: nil)
    }

    var remoteERC20Assets: URL? {
        guard let documentsDirectory = documentsDirectory else {
            return nil
        }
        return documentsDirectory.appendingPathComponent(FileName.Remote.erc20)
    }

    var remoteCustodialAssets: URL? {
        guard let documentsDirectory = documentsDirectory else {
            return nil
        }
        return documentsDirectory.appendingPathComponent(FileName.Remote.custodial)
    }

    private var documentsDirectory: URL? {
        try? FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        )
    }
}
