// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Foundation

/// Represents the possible outcomes of going through the transaction flow
public enum TransactionFlowResult: Equatable {
    case abandoned
    case completed
}
