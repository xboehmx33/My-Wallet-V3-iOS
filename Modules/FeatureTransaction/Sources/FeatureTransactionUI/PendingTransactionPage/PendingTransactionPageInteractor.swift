// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import DIKit
import FeatureTransactionDomain
import Localization
import PlatformKit
import PlatformUIKit
import RIBs
import RxCocoa
import RxSwift

protocol PendingTransactionPageRouting: Routing {}

protocol PendingTransactionPageListener: AnyObject {
    func closeFlow()
    func showKYCUpgradePrompt()
}

protocol PendingTransactionPagePresentable: Presentable, PendingTransactionPageViewControllable {
    func connect(state: Driver<PendingTransactionPageState>) -> Driver<PendingTransactionPageState.Effect>
}

final class PendingTransactionPageInteractor: PresentableInteractor<PendingTransactionPagePresentable>, PendingTransactionPageInteractable {

    weak var router: PendingTransactionPageRouting?
    weak var listener: PendingTransactionPageListener?

    private let pendingTransationStateProvider: PendingTransactionStateProviding
    private let transactionModel: TransactionModel
    private let analyticsHook: TransactionAnalyticsHook
    private let sendEmailNotificationService: SendEmailNotificationServiceAPI

    private var cancellables = Set<AnyCancellable>()
    private var disposeBag = DisposeBag()

    init(
        transactionModel: TransactionModel,
        presenter: PendingTransactionPagePresentable,
        action: AssetAction,
        analyticsHook: TransactionAnalyticsHook = resolve(),
        sendEmailNotificationService: SendEmailNotificationServiceAPI = resolve()
    ) {
        pendingTransationStateProvider = PendingTransctionStateProviderFactory.pendingTransactionStateProvider(
            action: action
        )
        self.transactionModel = transactionModel
        self.analyticsHook = analyticsHook
        self.sendEmailNotificationService = sendEmailNotificationService
        super.init(presenter: presenter)
    }

    override func didBecomeActive() {
        super.didBecomeActive()

        let state: Driver<PendingTransactionPageState> = pendingTransationStateProvider
            .connect(state: transactionModel.state)
            .asDriver(onErrorJustReturn: .empty)

        presenter
            .connect(state: state)
            .drive(onNext: handle(effect:))
            .disposeOnDeactivate(interactor: self)

        let executionStatus = transactionModel.state.map(\.executionStatus)

        executionStatus
            .asObservable()
            .withLatestFrom(transactionModel.state) { ($0, $1) }
            .subscribe(onNext: { [weak self] executionStatus, transactionState in
                guard let self = self else { return }
                switch executionStatus {
                case .inProgress, .notStarted, .pending:
                    break
                case .error:
                    self.analyticsHook.onTransactionFailure(with: transactionState)
                case .completed:
                    self.analyticsHook.onTransactionSuccess(with: transactionState)
                    self.triggerSendEmailNotification(transactionState)
                }
            })
            .disposed(by: disposeBag)
    }

    // MARK: - Private methods

    private func handle(effect: PendingTransactionPageState.Effect) {
        switch effect {
        case .close:
            listener?.closeFlow()
        case .upgradeKYCTier:
            listener?.showKYCUpgradePrompt()
        case .none:
            break
        }
    }

    private func triggerSendEmailNotification(_ transactionState: TransactionState) {
        switch transactionState.action {
        case .interestTransfer,
             .send:
            if transactionState.source is NonCustodialAccount {
                sendEmailNotificationService
                    .postSendEmailNotificationTrigger(transactionState.amount)
                    .subscribe()
                    .store(in: &cancellables)
            }
        case .deposit,
             .receive,
             .interestWithdraw,
             .buy,
             .sell,
             .swap,
             .withdraw,
             .viewActivity,
             .sign:
            break
        }
    }

    override func willResignActive() {
        super.willResignActive()
    }
}
