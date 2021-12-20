// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Foundation

struct BlockNumberRequest: Encodable {
    let id: Int = 0
    let jsonrpc: String = "2.0"
    let method: String = "eth_blockNumber"
}
