// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import RxSwift

public protocol CryptoNonCustodialAccount: CryptoAccount, NonCustodialAccount {

    func updateLabel(_ newLabel: String) -> AnyPublisher<Void, Never>

    /// Creates and return a On Chain `TransactionEngine` for this account `CryptoCurrency`.
    func createTransactionEngine() -> Any
}

extension CryptoNonCustodialAccount {

    public var isBitPaySupported: Bool {
        if asset == .coin(.bitcoin) {
            return true
        }

        return false
    }

    public var requireSecondPassword: Single<Bool> {
        .just(false)
    }

    public var requireSecondPasswordPublisher: AnyPublisher<Bool, Never> {
        .just(false)
    }

    public var isFunded: Single<Bool> {
        balance
            .map(\.isPositive)
    }

    public var isFundedPublisher: AnyPublisher<Bool, Never> {
        balance
            .map(\.isPositive)
            .asPublisher()
            .crashOnError()
    }

    public func updateLabel(_ newLabel: String) -> AnyPublisher<Void, Never> {
        .just(())
    }

    public func canPerformInterestTransfer() -> Single<Bool> {
        let isEligible = disabledReason
            .map(\.isEligible)
            .asSingle()
        return Single
            .zip(isEligible, isFunded)
            .map { $0 && $1 }
            .catchErrorJustReturn(false)
    }

    /// The `OrderDirection` for which an `CryptoNonCustodialAccount` could have custodial events.
    public var custodialDirections: Set<OrderDirection> {
        [.fromUserKey, .onChain]
    }

    /// Treats an `[TransactionalActivityItemEvent]`, replacing any event matching one of the `SwapActivityItemEvent` with the said match.
    public static func reconcile(
        swapEvents: [SwapActivityItemEvent],
        noncustodial: [TransactionalActivityItemEvent]
    ) -> [ActivityItemEvent] {
        (noncustodial.map(ActivityItemEvent.transactional) + swapEvents.map(ActivityItemEvent.swap))
            .map { event in
                if case .swap(let swapEvent) = event, swapEvent.pair.outputCurrencyType.isFiatCurrency {
                    return .buySell(.init(swapActivityItemEvent: swapEvent))
                }
                return event
            }
    }
}
