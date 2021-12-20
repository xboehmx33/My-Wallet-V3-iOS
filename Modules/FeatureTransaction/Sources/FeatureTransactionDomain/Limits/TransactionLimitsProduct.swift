// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import PlatformKit

public enum TransactionLimitsProduct {
    case simplebuy
    case swap(OrderDirection)
    case sell(OrderDirection)
}
