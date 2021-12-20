// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Localization
import MoneyKit
import PlatformKit
import PlatformUIKit
import RxCocoa
import RxSwift
import ToolKit

final class SwapPendingTransactionStateProvider: PendingTransactionStateProviding {

    private typealias LocalizationIds = LocalizationConstants.Transaction.Swap.Completion

    // MARK: - PendingTransactionStateProviding

    func connect(state: Observable<TransactionState>) -> Observable<PendingTransactionPageState> {
        state
            .map(weak: self) { (self, state) in
                switch state.executionStatus {
                case .inProgress,
                     .pending,
                     .notStarted:
                    return self.pending(state: state)
                case .completed:
                    return self.success(state: state)
                case .error:
                    return self.failed(state: state)
                }
            }
    }

    // MARK: - Private Functions

    private func success(state: TransactionState) -> PendingTransactionPageState {
        .init(
            title: String(
                format: LocalizationIds.Success.title,
                state.amount.displayString
            ),
            subtitle: String(
                format: LocalizationIds.Success.description,
                state.destination?.currencyType.cryptoCurrency?.name ?? ""
            ),
            compositeViewType: .composite(
                .init(
                    baseViewType: .templateImage(name: "swap-icon", bundle: .platformUIKit, templateColor: .white),
                    sideViewAttributes: .init(
                        type: .image(PendingStateViewModel.Image.success.imageResource),
                        position: .radiusDistanceFromCenter
                    ),
                    backgroundColor: .primaryButton,
                    cornerRadiusRatio: 0.5
                )
            ),
            effect: .close,
            primaryButtonViewModel: .primary(with: LocalizationIds.Success.action)
        )
    }

    private func pending(state: TransactionState) -> PendingTransactionPageState {
        let sent = state.amount
        let received: MoneyValue
        switch state.moneyValueFromDestination() {
        case .success(let value):
            received = value
        case .failure:
            switch state.destination {
            case nil:
                fatalError("Expected a Destination: \(state)")
            case let account as SingleAccount:
                received = .zero(currency: account.currencyType)
            case let cryptoTarget as CryptoTarget:
                received = .zero(currency: cryptoTarget.asset)
            default:
                fatalError("Unsupported state.destination: \(String(reflecting: state.destination))")
            }
        }
        let title: String
        if !received.isZero, !sent.isZero {
            // If we have both sent and receive values:
            title = String(
                format: LocalizationIds.Pending.title,
                sent.displayString,
                received.displayString
            )
        } else {
            // If we have invalid inputs but we should continue.
            title = String(
                format: LocalizationIds.Pending.title,
                sent.displayCode,
                received.displayCode
            )
        }
        return .init(
            title: title,
            subtitle: LocalizationIds.Pending.description,
            compositeViewType: .composite(
                .init(
                    baseViewType: .templateImage(name: "swap-icon", bundle: .platformUIKit, templateColor: .white),
                    sideViewAttributes: .init(type: .loader, position: .radiusDistanceFromCenter),
                    backgroundColor: .primaryButton,
                    cornerRadiusRatio: 0.5
                )
            )
        )
    }

    private func failed(state: TransactionState) -> PendingTransactionPageState {
        .init(
            title: state.transactionErrorDescription,
            subtitle: LocalizationIds.Failure.description,
            compositeViewType: .composite(
                .init(
                    baseViewType: .templateImage(name: "swap-icon", bundle: .platformUIKit, templateColor: .white),
                    sideViewAttributes: .init(
                        type: .image(PendingStateViewModel.Image.circleError.imageResource),
                        position: .radiusDistanceFromCenter
                    ),
                    backgroundColor: .primaryButton,
                    cornerRadiusRatio: 0.5
                )
            ),
            effect: .close,
            primaryButtonViewModel: .primary(with: LocalizationConstants.okString)
        )
    }
}
