// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Foundation
import ToolKit

/// The derived Wallet from the response model, `BlockchainWallet`
final class Wallet {

    var guid: String
    var sharedKey: String
    var doubleEncrypted: Bool
    var doublePasswordHash: String?
    var metadataHDNode: String
    let hdWallets: [HDWallet]

    init(from blockchainWallet: BlockchainWallet) {
        guid = blockchainWallet.guid
        sharedKey = blockchainWallet.sharedKey
        doubleEncrypted = blockchainWallet.doubleEncryption
        doublePasswordHash = blockchainWallet.doublePasswordHash
        metadataHDNode = blockchainWallet.metadataHDNode
        hdWallets = blockchainWallet.hdWallets
    }
}

func getSeedHex(
    wallet: Wallet,
    secondPassword: String?
) -> Result<String, WalletError> {
    guard !wallet.doubleEncrypted else {
        // TODO: handle double password
        unimplemented()
    }
    guard let seedHex = wallet.hdWallets.first?.seedHex else {
        return .failure(.initialization(.missingSeedHex)) // Should we crash?
    }
    return .success(seedHex)
}
