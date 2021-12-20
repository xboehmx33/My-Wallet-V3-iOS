// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import DIKit
import MoneyKit
import PlatformKit
import RxCocoa
import RxSwift
import RxToolKit

struct ValidatedData {
    let currency: FiatCurrency
    let beneficiary: Beneficiary
    let amount: FiatValue
}

final class WithdrawAmountValidationService {

    enum Input {
        case amount(MoneyValue)
        case withdrawMax
        case empty
    }

    enum State {
        case valid(data: ValidatedData)
        case maxLimitExceeded(MoneyValue)
        case minLimitNotReached(MoneyValue)
        case empty

        var isValid: Bool {
            switch self {
            case .valid:
                return true
            default:
                return false
            }
        }

        var isEmpty: Bool {
            switch self {
            case .empty:
                return true
            default:
                return false
            }
        }
    }

    let balance: Single<MoneyValue>
    let account: Observable<SingleAccount>
    private let minValue: Observable<MoneyValue>

    // MARK: - Services

    private let coincore: CoincoreAPI

    // MARK: - Properties

    private let fiatCurrency: FiatCurrency
    private let beneficiary: Beneficiary

    init(
        fiatCurrency: FiatCurrency,
        beneficiary: Beneficiary,
        coincore: CoincoreAPI = resolve(),
        withdrawFeeService: WithdrawalServiceAPI = resolve()
    ) {
        self.fiatCurrency = fiatCurrency
        self.beneficiary = beneficiary
        self.coincore = coincore

        account = coincore.allAccounts
            .asObservable()
            .asSingle()
            .compactMap { [fiatCurrency] group in
                group.accounts.first(where: { $0.currencyType == fiatCurrency.currencyType })
            }
            .asObservable()
            .share(replay: 1, scope: .whileConnected)

        balance = account
            .asObservable()
            .flatMap { account -> Single<MoneyValue> in
                account.balance
            }
            .asSingle()

        minValue = withdrawFeeService.withdrawalMinAmount(for: fiatCurrency, paymentMethodType: .bankTransfer)
            .asObservable()
            .map(\.moneyValue)
            .startWith(.zero(currency: fiatCurrency))
            .share(replay: 1, scope: .whileConnected)
    }

    func connect(inputs: Observable<Input>) -> Observable<State> {
        Observable.combineLatest(inputs, minValue)
            .flatMap { [balance] action, minValue -> Observable<State> in
                balance.map { balance -> State in
                    switch action {
                    case .withdrawMax:
                        guard !balance.isZero else { return .empty }
                        guard let fiatValue = balance.fiatValue else { return .empty }
                        return .valid(data: self.data(from: fiatValue))
                    case .amount(let value):
                        guard !value.isZero else { return .empty }
                        guard let fiatValue = value.fiatValue else { return .empty }
                        guard try value <= balance else {
                            return .maxLimitExceeded(balance)
                        }
                        guard try value >= minValue else {
                            return .minLimitNotReached(minValue)
                        }
                        return .valid(data: self.data(from: fiatValue))
                    default:
                        return .empty
                    }
                }
                .asObservable()
            }
    }

    private func data(from amount: FiatValue) -> ValidatedData {
        ValidatedData(
            currency: fiatCurrency,
            beneficiary: beneficiary,
            amount: amount
        )
    }
}

extension WithdrawAmountValidationService.State {

    var data: ValidatedData? {
        switch self {
        case .valid(let data):
            return data
        default:
            return nil
        }
    }

    var toAmountInteractorState: AmountInteractorState {
        switch self {
        case .empty:
            return .empty
        case .maxLimitExceeded(let value):
            return .maxLimitExceeded(value)
        case .minLimitNotReached(let value):
            return .underMinLimit(value)
        case .valid:
            return .inBounds
        }
    }
}
