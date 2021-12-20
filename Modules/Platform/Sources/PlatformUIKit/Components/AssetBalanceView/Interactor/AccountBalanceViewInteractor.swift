// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import DIKit
import MoneyKit
import PlatformKit
import RxRelay
import RxSwift
import ToolKit

public final class AccountBalanceViewInteractor: AssetBalanceViewInteracting {

    public typealias InteractionState = AssetBalanceViewModel.State.Interaction
    private typealias Model = AssetBalanceViewModel.Value.Interaction

    // MARK: - Exposed Properties

    public var state: Observable<InteractionState> {
        Observable
            .combineLatest(
                fiatCurrencyService.displayCurrencyPublisher.asObservable(),
                refreshRelay.asObservable()
            )
            .map(\.0)
            .flatMapLatest(weak: self) { (self, fiatCurrency) in
                self.stateSingle(fiatCurrency: fiatCurrency).asObservable()
            }
    }

    private func stateSingle(fiatCurrency: FiatCurrency) -> Single<InteractionState> {
        Single.zip(
            account.balancePair(fiatCurrency: fiatCurrency).asSingle(),
            account.pendingBalance
        )
        .map { balancePair, pendingBalance in
            AssetBalanceViewModel.Value.Interaction(
                primaryValue: balancePair.quote,
                secondaryValue: balancePair.base,
                pendingValue: pendingBalance
            )
        }
        .map(InteractionState.loaded)
    }

    // MARK: - Private Accessors

    private let account: BlockchainAccount
    private let fiatCurrencyService: FiatCurrencyServiceAPI
    private let refreshRelay = BehaviorRelay<Void>(value: ())

    // MARK: - Setup

    public init(
        account: BlockchainAccount,
        fiatCurrencyService: FiatCurrencyServiceAPI = resolve()
    ) {
        self.account = account
        self.fiatCurrencyService = fiatCurrencyService
    }

    public func refresh() {
        refreshRelay.accept(())
    }
}
