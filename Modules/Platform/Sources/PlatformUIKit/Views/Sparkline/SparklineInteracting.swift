// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Foundation
import MoneyKit
import RxRelay
import RxSwift

public protocol SparklineInteracting: AnyObject {

    /// The currency displayed in the Sparkline
    var cryptoCurrency: CryptoCurrency { get }

    /// The historical prices and balance
    /// calculation state
    var calculationState: Observable<SparklineCalculationState> { get }
}
