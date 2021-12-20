// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import AnalyticsKit
import DIKit
import MoneyKit
import PlatformKit
import PlatformUIKit
import RxCocoa
import RxSwift
import ToolKit

final class NonCustodialActionScreenPresenter: WalletActionScreenPresenting {

    // MARK: - Types

    typealias AccessibilityId = Accessibility.Identifier
    typealias CellType = WalletActionCellType

    // MARK: - Properties

    var sections: Observable<[WalletActionItemsSectionViewModel]> {
        sectionsRelay
            .asObservable()
    }

    let selectionRelay: PublishRelay<WalletActionCellType> = .init()

    let assetBalanceViewPresenter: CurrentBalanceCellPresenter

    var currency: CurrencyType {
        interactor.currency
    }

    // MARK: - Private Properties

    private var actionCellPresenters: Single<[WalletActionCellPresenter]> {
        interactor
            .availableActions
            .map { actions in
                actions.compactMap(\.walletAction)
            }
            .map { $0.sorted() }
            .map { [currency] actions in
                actions.map {
                    WalletActionCellPresenter(
                        currencyType: currency,
                        action: $0
                    )
                }
            }
    }

    private let sectionsRelay = BehaviorRelay<[WalletActionItemsSectionViewModel]>(value: [])
    private let interactor: WalletActionScreenInteracting
    private let analyticsRecorder: AnalyticsEventRecorderAPI
    private let disposeBag = DisposeBag()

    // MARK: - Setup

    init(
        using interactor: WalletActionScreenInteracting,
        stateService: NonCustodialActionStateServiceAPI,
        featureConfigurator: FeatureConfiguring = resolve(),
        analyticsRecorder: AnalyticsEventRecorderAPI = resolve()
    ) {
        self.interactor = interactor
        self.analyticsRecorder = analyticsRecorder
        let currency = interactor.currency
        let descriptionValue: () -> Observable<String> = {
            .just(currency.name)
        }

        assetBalanceViewPresenter = CurrentBalanceCellPresenter(
            interactor: interactor.balanceCellInteractor,
            descriptionValue: descriptionValue,
            currency: interactor.currency,
            viewAccessibilitySuffix: "\(AccessibilityId.AssetDetails.CurrentBalanceCell.view)",
            titleAccessibilitySuffix: "\(AccessibilityId.AssetDetails.CurrentBalanceCell.titleValue)",
            descriptionAccessibilitySuffix: "\(AccessibilityId.AssetDetails.CurrentBalanceCell.descriptionValue)",
            pendingAccessibilitySuffix: "\(AccessibilityId.AssetDetails.CurrentBalanceCell.pendingValue)",
            descriptors: .default(
                cryptoAccessiblitySuffix: "\(AccessibilityId.WalletActionSheet.NonCustodial.cryptoValue)",
                fiatAccessiblitySuffix: "\(AccessibilityId.WalletActionSheet.NonCustodial.fiatValue)"
            )
        )

        actionCellPresenters
            .catchError { _ in
                .just([])
            }
            .map { [assetBalanceViewPresenter] presenters -> [WalletActionCellType] in
                [.balance(assetBalanceViewPresenter)] +
                    presenters.map { WalletActionCellType.default($0) }
            }
            .map { cellTypes in
                [WalletActionItemsSectionViewModel(items: cellTypes)]
            }
            .asObservable()
            .bindAndCatch(to: sectionsRelay)
            .disposed(by: disposeBag)

        selectionRelay
            .bind { model in
                guard case .default(let presenter) = model else { return }
                switch presenter.action {
                case .activity:
                    stateService.selectionRelay.accept(.next(.activity))
                case .swap:
                    stateService.selectionRelay.accept(.next(.swap))
                    analyticsRecorder.record(event: AnalyticsEvents.New.Swap.swapClicked(origin: .currencyPage))
                case .send:
                    stateService.selectionRelay.accept(.next(.send))
                case .receive:
                    stateService.selectionRelay.accept(.next(.receive))
                case .buy:
                    stateService.selectionRelay.accept(.next(.buy))
                case .deposit:
                    // Not possible for a Non Custodial wallet to 'deposit'.
                    break
                case .interest:
                    // Not possible for a Non Custodial wallet to 'interest'.
                    break
                case .sell:
                    stateService.selectionRelay.accept(.next(.sell))
                case .withdraw:
                    // Not possible for a Non Custodial wallet to 'withdraw'.
                    break
                }
            }
            .disposed(by: disposeBag)
    }
}

extension AssetAction {
    fileprivate var walletAction: WalletAction? {
        switch self {
        case .interestWithdraw,
             .interestTransfer,
             .sign:
            return nil
        case .viewActivity:
            return .activity
        case .buy:
            return .buy
        case .deposit:
            return .deposit
        case .receive:
            return .receive
        case .sell:
            return .sell
        case .send:
            return .send
        case .swap:
            return .swap
        case .withdraw:
            return .withdraw
        }
    }
}
