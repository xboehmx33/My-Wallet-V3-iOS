// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BigInt
@testable import EthereumKit
import PlatformKit
import TestKit

enum MockEthereumWalletTestData {
    static let walletId = MockWalletTestData.walletId
    static let email = MockWalletTestData.email

    static let mnemonic = MockWalletTestData.Bip39.mnemonic
    static let account = "0xE408d13921DbcD1CBcb69840e4DA465Ba07B7e5e"

    static let privateKeyHex = "de6e182c9456edeb1148387dadc8f981905377279feb9547d095152ef0f569d9"
    static let privateKeyBase64 = "3m4YLJRW7esRSDh9rcj5gZBTdyef65VH0JUVLvD1adk="
    static let privateKeyData = Data(hex: MockEthereumWalletTestData.privateKeyHex)

    static let privateKey = EthereumPrivateKey(
        mnemonic: MockEthereumWalletTestData.mnemonic,
        data: MockEthereumWalletTestData.privateKeyData
    )
    static let keyPair = EthereumKeyPair(
        accountID: MockEthereumWalletTestData.account,
        privateKey: MockEthereumWalletTestData.privateKey
    )

    enum Transaction {
        static let to = "0x3535353535353535353535353535353535353535"
        static let value: BigUInt = 1
        static let nonce: BigUInt = 9
        static let gasPrice: BigUInt = 11000000000
        static let gasLimit: BigUInt = 21000
        static let gasLimitContract: BigUInt = 65000
        static let data: Data? = Data()
    }
}

extension EthereumTransactionCandidate {
    static var defaultMock: EthereumTransactionCandidate {
        EthereumTransactionCandidate(
            to: EthereumAddress(address: MockEthereumWalletTestData.Transaction.to)!,
            gasPrice: MockEthereumWalletTestData.Transaction.gasPrice,
            gasLimit: MockEthereumWalletTestData.Transaction.gasLimit,
            value: MockEthereumWalletTestData.Transaction.value,
            transferType: .transfer()
        )
    }
}

extension EthereumAssetAccountDetails {
    static var defaultMock: EthereumAssetAccountDetails {
        .init(
            account: .defaultMock,
            balance: .zero(currency: .coin(.ethereum)),
            nonce: UInt64(MockEthereumWalletTestData.Transaction.nonce)
        )
    }
}

extension EthereumWalletAccount {
    static var defaultMock: EthereumWalletAccount {
        EthereumWalletAccount(
            index: 0,
            publicKey: MockEthereumWalletTestData.account,
            label: "",
            archived: false
        )
    }
}
