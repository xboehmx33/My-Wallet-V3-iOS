// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import MoneyKit
import PlatformKit

public struct EthereumAddress: AssetAddress, Hashable {

    public let publicKey: String
    public let cryptoCurrency: CryptoCurrency = .coin(.ethereum)

    public init(string address: String) throws {
        try EthereumAddressValidator.validate(address: address)
        guard let eip55Address = EthereumAddressValidator.toChecksumAddress(address) else {
            throw AddressValidationError.eip55ChecksumFailed
        }
        publicKey = eip55Address
    }

    public init?(address: String) {
        try? self.init(string: address)
    }
}
