// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import RxRelay
import RxSwift
import ToolKit

public protocol ActivityItemBalanceFetching {
    /// The pair exchange service
    var pairExchangeService: PairExchangeServiceAPI { get }

    /// The calculation state of the `MoneyValuePair`
    var calculationState: Observable<MoneyValuePairCalculationState> { get }

    /// Trigger a refresh on the balance and exchange rate
    func refresh()
}

public final class ActivityItemBalanceFetcher: ActivityItemBalanceFetching {

    public let pairExchangeService: PairExchangeServiceAPI

    public var calculationState: Observable<MoneyValuePairCalculationState> {
        _ = setup
        return calculationStateRelay.asObservable()
    }

    // MARK: - Private Properties

    private let calculationStateRelay = BehaviorRelay<MoneyValuePairCalculationState>(value: .calculating)
    private let disposeBag = DisposeBag()
    private let moneyValue: MoneyValue

    private lazy var setup: Void = {
        pairExchangeService
            .fiatPrice
            .map(weak: self) { (self, fiatPrice) -> MoneyValuePair in
                MoneyValuePair(base: self.moneyValue, exchangeRate: .init(fiatValue: fiatPrice))
            }
            .map { .value($0) }
            .startWith(.calculating)
            .catchErrorJustReturn(.calculating)
            .bindAndCatch(to: calculationStateRelay)
            .disposed(by: disposeBag)
    }()

    // MARK: - Private Properties

    public init(pairExchangeService: PairExchangeServiceAPI, moneyValue: MoneyValue) {
        self.pairExchangeService = pairExchangeService
        self.moneyValue = moneyValue
    }

    public func refresh() {
        pairExchangeService.fetchTriggerRelay.accept(())
    }
}
