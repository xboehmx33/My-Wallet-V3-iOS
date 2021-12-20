// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Foundation

/// A representation of a  transaction that can be passed to Ethereum JSON RPC methods.
///
/// All parameters are hexadecimal String values.
public struct EthereumJsonRpcTransaction: Codable {

    /// from: DATA, 20 Bytes - The address the transaction is send from.
    let from: String

    /// to: DATA, 20 Bytes - (optional when creating new contract) The address the transaction is directed to.
    let to: String?

    /// data: DATA - The compiled code of a contract OR the hash of the invoked method signature and encoded parameters. For details see Ethereum Contract ABI
    let data: String

    /// gas: QUANTITY - (optional, default: 90000) Integer of the gas provided for the transaction execution. It will return unused gas.
    let gas: String?

    /// gasPrice: QUANTITY - (optional, default: To-Be-Determined) Integer of the gasPrice used for each paid gas
    let gasPrice: String?

    /// value: QUANTITY - (optional) Integer of the value sent with this transaction
    let value: String?

    /// nonce: QUANTITY - (optional) Integer of a nonce. This allows to overwrite your own pending transactions that use the same nonce.
    let nonce: String?

    public init(
        from: String,
        to: String?,
        data: String,
        gas: String?,
        gasPrice: String?,
        value: String?,
        nonce: String?
    ) {
        self.from = from
        self.to = to
        self.data = data
        self.gas = gas
        self.gasPrice = gasPrice
        self.value = value
        self.nonce = nonce
    }
}
