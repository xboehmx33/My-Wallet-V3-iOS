// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import FeatureTransactionDomain
import Localization
import MoneyKit
import PlatformKit
import PlatformUIKit
import RxSwift
import ToolKit

final class BuyPendingTransactionStateProvider: PendingTransactionStateProviding {

    private typealias LocalizationIds = LocalizationConstants.Transaction.Buy.Completion

    private let coreBuyIcon: CompositeStatusViewType.Composite.BaseViewType = .templateImage(
        name: "plus-icon",
        bundle: .platformUIKit,
        templateColor: .white
    )

    // MARK: - PendingTransactionStateProviding

    func connect(state: Observable<TransactionState>) -> Observable<PendingTransactionPageState> {
        state.map(weak: self) { (self, state) in
            switch state.executionStatus {
            case .inProgress,
                 .notStarted:
                return self.inProgress(state: state)
            case .pending:
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
        guard let destinationCurrency = state.destination?.currencyType else {
            impossible("Expected a destination to there for a transaction that has succeeded")
        }
        let canUpgradeTier = canUpgradeTier(from: state.userKYCStatus?.tiers)
        return .init(
            title: String(
                format: LocalizationIds.Success.title,
                state.amount.displayString
            ),
            subtitle: String(
                format: LocalizationIds.Success.description,
                destinationCurrency.name
            ),
            compositeViewType: .composite(
                .init(
                    baseViewType: coreBuyIcon,
                    sideViewAttributes: .init(
                        type: .image(.local(name: "v-success-icon", bundle: .platformUIKit)),
                        position: .radiusDistanceFromCenter
                    ),
                    backgroundColor: .primaryButton,
                    cornerRadiusRatio: 0.5
                )
            ),
            effect: .close,
            primaryButtonViewModel: .primary(with: LocalizationIds.Success.action),
            secondaryButtonViewModel: canUpgradeTier ? .secondary(with: LocalizationIds.Success.upgrade) : nil
        )
    }

    private func inProgress(state: TransactionState) -> PendingTransactionPageState {
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
                format: LocalizationIds.InProgress.title,
                received.displayString,
                sent.displayString
            )
        } else {
            // If we have invalid inputs but we should continue.
            title = String(
                format: LocalizationIds.InProgress.title,
                received.displayCode,
                sent.displayCode
            )
        }
        return .init(
            title: title,
            subtitle: LocalizationIds.InProgress.description,
            compositeViewType: .composite(
                .init(
                    baseViewType: coreBuyIcon,
                    sideViewAttributes: .init(type: .loader, position: .radiusDistanceFromCenter),
                    backgroundColor: .primaryButton,
                    cornerRadiusRatio: 0.5
                )
            )
        )
    }

    private func pending(state: TransactionState) -> PendingTransactionPageState {
        let canUpgradeTier = canUpgradeTier(from: state.userKYCStatus?.tiers)
        return PendingTransactionPageState(
            title: LocalizationIds.Pending.title,
            subtitle: LocalizationIds.Pending.description,
            compositeViewType: .composite(
                .init(
                    baseViewType: coreBuyIcon,
                    sideViewAttributes: .init(
                        type: .image(.local(name: "clock-error-icon", bundle: .platformUIKit)),
                        position: .radiusDistanceFromCenter
                    ),
                    backgroundColor: .primaryButton,
                    cornerRadiusRatio: 0.5
                )
            ),
            effect: .close,
            primaryButtonViewModel: .primary(with: LocalizationConstants.okString),
            secondaryButtonViewModel: canUpgradeTier ? .secondary(with: LocalizationIds.Success.upgrade) : nil
        )
    }

    private func failed(state: TransactionState) -> PendingTransactionPageState {
        .init(
            title: state.transactionErrorDescription,
            subtitle: LocalizationIds.Failure.description,
            compositeViewType: .composite(
                .init(
                    baseViewType: coreBuyIcon,
                    sideViewAttributes: .init(
                        type: .image(.local(name: "circular-error-icon", bundle: .platformUIKit)),
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

    private func canUpgradeTier(from kycTiers: KYC.UserTiers?) -> Bool {
        // Default to Tier 2 if needed so we don't show the upgrade prompt unnecessarily
        (kycTiers?.latestApprovedTier ?? .tier2) < .tier2
    }
}
