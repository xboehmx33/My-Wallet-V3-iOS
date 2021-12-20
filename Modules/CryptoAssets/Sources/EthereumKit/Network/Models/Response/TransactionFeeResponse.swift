// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import PlatformKit

struct TransactionFeeResponse: Decodable {
    let gasLimit: Int
    let gasLimitContract: Int
    let regular: Int
    let priority: Int
}
