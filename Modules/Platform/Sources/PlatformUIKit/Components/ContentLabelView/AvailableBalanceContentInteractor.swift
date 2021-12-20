// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import DIKit
import MoneyKit
import PlatformKit
import RxCocoa
import RxSwift
import RxToolKit
import ToolKit

public protocol ContentLabelViewInteractorAPI {
    var contentCalculationState: Observable<ValueCalculationState<String>> { get }
}

public final class AvailableBalanceContentInteractor: ContentLabelViewInteractorAPI {

    public let contentCalculationState: Observable<ValueCalculationState<String>>

    /// Creates a `AvailableBalanceContentInteractor` that will stream the
    /// balance (in the given `CurrencyType`) of the first account of the given `CurrencyType`.
    public init(currencyType: CurrencyType, coincore: CoincoreAPI) {

        let balance = coincore.allAccounts
            .asObservable()
            .asSingle()
            .compactMap { group in
                group.accounts.first { $0.currencyType == currencyType }
            }
            .asObservable()
            .flatMap { account -> Single<MoneyValue> in
                account.balance
            }

        contentCalculationState = balance
            .map { .value($0.toDisplayString(includeSymbol: true)) }
            .share(replay: 1, scope: .whileConnected)
    }

    /// Creates a `AvailableBalanceContentInteractor` that will stream the
    /// balance of the given `BlockchainAccount` in its own `CurrencyType`.
    init(account: BlockchainAccount) {
        contentCalculationState = account.balance
            .asObservable()
            .map { .value($0.toDisplayString(includeSymbol: true)) }
            .share(replay: 1, scope: .whileConnected)
    }
}
