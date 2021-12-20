// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Foundation
import PlatformKit

public enum EthereumKitValidationError: TransactionValidationError {
    case noGasPrice
    case noGasLimit
    case unknown
}
