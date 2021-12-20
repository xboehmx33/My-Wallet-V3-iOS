// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import DIKit
import FeatureTransactionDomain
import Localization
import MoneyKit
import PlatformKit
import PlatformUIKit
import RxCocoa
import RxRelay
import RxSwift
import ToolKit
import UIComponentsKit
import UIKit

protocol ConfirmationPageContentReducing {
    /// The title of the checkout screen
    var title: String { get }
    /// The `Cells` on the `ConfirmationPage`
    var cells: [DetailsScreen.CellType] { get }
    var buttons: [ButtonViewModel] { get }
    var continueButtonViewModel: ButtonViewModel { get }
    var cancelButtonViewModel: ButtonViewModel { get }
}

// swiftlint:disable type_body_length
final class ConfirmationPageContentReducer: ConfirmationPageContentReducing {

    // MARK: - Types

    typealias ConfirmationModel = TransactionConfirmation.Model

    // MARK: - Private Types

    private typealias LocalizedString = LocalizationConstants.Transaction

    // MARK: - CheckoutScreenContentReducing

    var title: String = ""
    var cells: [DetailsScreen.CellType] = []
    var navigationBarAppearance: DetailsScreen.NavigationBarAppearance = .hidden

    let continueButtonViewModel: ButtonViewModel
    let cancelButtonViewModel: ButtonViewModel

    /// Buttons that should be displayed on the confirmation screen.
    /// Wallet connect transactions will require a `Cancel` button so
    /// we will have to introspect the `TransactionState` to determine
    /// what buttons to show. This is the only time the `Cancel` button
    /// should be visible.
    var buttons: [ButtonViewModel] = []

    let termsCheckboxViewModel: CheckboxViewModel = .termsCheckboxViewModel

    /// A `CheckboxViewModel` that prompts the user to confirm
    /// that they will be transferring funds to their rewards account.
    /// This `CheckboxViewModel` needs data from the `TransactionState`
    /// so we cannot initialize until we receive it.
    var transferCheckboxViewModel: CheckboxViewModel?

    let messageRecorder: MessageRecording
    let transferAgreementUpdated = PublishRelay<Bool>()
    let termsUpdated = PublishRelay<Bool>()
    let hyperlinkTapped = PublishRelay<TitledLink>()
    let memoUpdated = PublishRelay<(String, TransactionConfirmation.Model.Memo)>()
    private let memoModel: TextFieldViewModel
    private var disposeBag = DisposeBag()

    // MARK: - Private Properties

    init(messageRecorder: MessageRecording = resolve()) {
        self.messageRecorder = messageRecorder
        cancelButtonViewModel = .cancel(with: LocalizedString.Confirmation.cancel)
        continueButtonViewModel = .primary(with: "")
        memoModel = TextFieldViewModel(
            with: .memo,
            validator: TextValidationFactory.General.alwaysValid,
            messageRecorder: messageRecorder
        )
    }

    func setup(for state: TransactionState) {
        disposeBag = DisposeBag()
        title = Self.screenTitle(state: state)
        continueButtonViewModel.textRelay.accept(Self.confirmCtaText(state: state))
        navigationBarAppearance = .custom(
            leading: state.stepsBackStack.isEmpty ? .none : .back,
            trailing: .none,
            barStyle: .darkContent(ignoresStatusBar: false, background: .white)
        )

        buttons = createButtons(state: state)
        cells = createCells(state: state)
    }

    private func createButtons(state: TransactionState) -> [ButtonViewModel] {
        var buttons = [continueButtonViewModel]
        if state.destination is StaticTransactionTarget {
            buttons.insert(cancelButtonViewModel, at: 0)
        }
        return buttons
    }

    // swiftlint:disable:next function_body_length
    private func createCells(state: TransactionState) -> [DetailsScreen.CellType] {
        guard let pendingTransaction = state.pendingTransaction else {
            return []
        }

        let amount = state.amount
        let fee = pendingTransaction.feeAmount
        let value = (try? amount + fee) ?? .zero(currency: amount.currency)

        let sourceLabel = state.source?.label ?? ""

        // NOTE: This is not ideal. We do not know the
        // amount, fee, and total amount for the transaction
        // until we receive the `TransactionState`. That means
        // we cannot initialize a `transferCheckboxViewModel` until
        // this `setup(for state:)` function is called. So, we check to
        // see if this is `nil` prior to initializing it.
        if transferCheckboxViewModel == nil {
            transferCheckboxViewModel = .init(
                inputs: [
                    .text(
                        string: String(
                            format: LocalizedString.Transfer.transferAgreement,
                            value.displayString,
                            sourceLabel
                        )
                    )
                ]
            )
        }

        let interactors: [DefaultLineItemCellPresenter] = pendingTransaction
            .confirmations
            .filter { confirmation -> Bool in
                !confirmation.isCustom
            }
            .compactMap(\.formatted)
            .map { data -> (title: LabelContentInteracting, subtitle: LabelContentInteracting) in
                (DefaultLabelContentInteractor(knownValue: data.0), DefaultLabelContentInteractor(knownValue: data.1))
            }
            .map { data in
                DefaultLineItemCellInteractor(title: data.title, description: data.subtitle)
            }
            .map { interactor in
                DefaultLineItemCellPresenter(
                    interactor: interactor,
                    accessibilityIdPrefix: interactor.title.stateRelay.value.value?.text ?? ""
                )
            }

        var bitpayItemIfNeeded: [DetailsScreen.CellType] = pendingTransaction
            .confirmations
            .filter(\.isBitPay)
            .compactMap(\.formatted)
            .map { data -> (title: LabelContentInteracting, subtitle: LabelContentInteracting) in
                (DefaultLabelContentInteractor(knownValue: data.0), DefaultLabelContentInteractor(knownValue: data.1))
            }
            .map { data in
                DefaultLineItemCellInteractor(title: data.title, description: data.subtitle)
            }
            .map { interactor -> DetailsScreen.CellType in
                let presenter = DefaultLineItemCellPresenter(
                    interactor: interactor,
                    accessibilityIdPrefix: interactor.title.stateRelay.value.value?.text ?? ""
                )
                setupBitPay(on: presenter)
                return .lineItem(presenter)
            }
        if !bitpayItemIfNeeded.isEmpty {
            bitpayItemIfNeeded.append(.separator)
        }

        let confirmationLineItems: [DetailsScreen.CellType] = interactors
            .reduce(into: [DetailsScreen.CellType]()) { result, lineItem in
                result.append(.lineItem(lineItem))
                result.append(.separator)
            }

        let errorModels: [DetailsScreen.CellType] = pendingTransaction.confirmations
            .filter(\.isErrorNotice)
            .compactMap(\.formatted)
            .map(\.subtitle)
            .map { subtitle -> DefaultLabelContentPresenter in
                DefaultLabelContentPresenter(
                    knownValue: subtitle,
                    descriptors: .init(
                        fontWeight: .semibold,
                        contentColor: .destructive,
                        fontSize: 14.0,
                        accessibility: .none
                    )
                )
            }
            .map { presenter -> DetailsScreen.CellType in
                .label(presenter)
            }

        let imageNoticeModels: [DetailsScreen.CellType] = pendingTransaction.confirmations
            .filter(\.isImageNotice)
            .compactMap { confirmation -> TransactionConfirmation.Model.ImageNotice? in
                switch confirmation {
                case .imageNotice(let model):
                    return model
                default:
                    return nil
                }
            }
            .map { model -> NoticeViewModel in
                let imageResource = URL(string: model.imageURL)
                    .flatMap(ImageResource.remote)
                let imageViewContent = ImageViewContent(
                    imageResource: imageResource,
                    accessibility: .none,
                    renderingMode: .normal
                )
                let title = LabelContent(text: model.title, font: .main(.semibold, 16), color: .darkTitleText)
                let subtitle = LabelContent(text: model.subtitle, font: .main(.medium, 12), color: .descriptionText)

                return NoticeViewModel(
                    imageViewContent: imageViewContent,
                    imageViewSize: .edge(40),
                    labelContents: [title, subtitle],
                    verticalAlignment: .center
                )
            }
            .map { model -> DetailsScreen.CellType in
                .notice(model)
            }

        let noticeModels: [DetailsScreen.CellType] = pendingTransaction.confirmations
            .filter(\.isNotice)
            .compactMap(\.formatted)
            .map(\.subtitle)
            .map { subtitle -> DefaultLabelContentPresenter in
                DefaultLabelContentPresenter(
                    knownValue: subtitle,
                    descriptors: .init(
                        fontWeight: .medium,
                        contentColor: .darkTitleText,
                        fontSize: 14,
                        accessibility: .none
                    )
                )
            }
            .map { presenter -> DetailsScreen.CellType in
                .label(presenter)
            }

        let memo: TransactionConfirmation.Model.Memo? = pendingTransaction
            .confirmations
            .filter(\.isMemo)
            .compactMap { confirmation -> TransactionConfirmation.Model.Memo? in
                guard case .memo(let memo) = confirmation else {
                    return nil
                }
                return memo
            }
            .first

        let terms: ConfirmationModel.AnyBoolOption<Bool>? = pendingTransaction
            .confirmations
            .filter(\.isTermsOfService)
            .compactMap { confirmation -> ConfirmationModel.AnyBoolOption<Bool>? in
                guard case .termsOfService(let value) = confirmation else {
                    return nil
                }
                return value
            }
            .first

        let transferAgreement: ConfirmationModel.AnyBoolOption<Bool>? = pendingTransaction
            .confirmations
            .filter(\.isTransferAgreement)
            .compactMap { confirmation -> ConfirmationModel.AnyBoolOption<Bool>? in
                guard case .transferAgreement(let value) = confirmation else {
                    return nil
                }
                return value
            }
            .first

        var memoModels: [DetailsScreen.CellType] = []
        if let memo = memo {
            let subtitle = memo.formatted?.subtitle ?? ""
            memoModel.originalTextRelay.accept(subtitle)
            memoModel
                .focusRelay
                .filter { $0 == .off(.endEditing) }
                .mapToVoid()
                .withLatestFrom(memoModel.textRelay)
                .distinctUntilChanged()
                .map { text in
                    (text: text, oldModel: memo)
                }
                .bind(to: memoUpdated)
                .disposed(by: disposeBag)
            memoModels.append(.textField(memoModel))
        }

        var checkboxModels: [DetailsScreen.CellType] = []
        if terms != nil, transferAgreement != nil {

            termsCheckboxViewModel
                .selectedRelay
                .distinctUntilChanged()
                .bind(to: termsUpdated)
                .disposed(by: disposeBag)

            termsCheckboxViewModel
                .tapRelay
                .asObservable()
                .bind(to: hyperlinkTapped)
                .disposed(by: disposeBag)

            transferCheckboxViewModel?
                .selectedRelay
                .distinctUntilChanged()
                .bind(to: transferAgreementUpdated)
                .disposed(by: disposeBag)

            checkboxModels.append(
                contentsOf: [
                    .checkbox(termsCheckboxViewModel),
                    .checkbox(transferCheckboxViewModel!)
                ]
            )
        }

        var disclaimer: [DetailsScreen.CellType] = []
        if TransactionFlowDescriptor.confirmDisclaimerVisibility(action: state.action) {
            let content = LabelContent(
                text: TransactionFlowDescriptor
                    .confirmDisclaimerText(
                        action: state.action,
                        currencyCode: state.asset.code,
                        accountLabel: state.destination?.label ?? ""
                    ),
                font: .main(.medium, 12),
                color: .descriptionText,
                alignment: .left,
                accessibility: .id("disclaimer")
            )
            disclaimer.append(.staticLabel(content))
        }

        let topCells: [DetailsScreen.CellType] = imageNoticeModels + noticeModels
        let midCells: [DetailsScreen.CellType] = bitpayItemIfNeeded + confirmationLineItems + memoModels
        let bottomCells: [DetailsScreen.CellType] = errorModels + disclaimer + checkboxModels
        return topCells + [.separator] + midCells + bottomCells
    }

    static func screenTitle(state: TransactionState) -> String {
        switch state.action {
        case .sign:
            return LocalizedString.Confirmation.signatureRequest
        case .send:
            return LocalizedString.Confirmation.sendRequest
        default:
            return LocalizedString.Confirmation.confirm
        }
    }

    static func confirmCtaText(state: TransactionState) -> String {
        switch state.action {
        case .swap:
            return LocalizedString.Swap.swapNow
        case .send:
            return LocalizedString.Confirmation.confirm
        case .buy:
            return LocalizedString.Swap.buyNow
        case .sell:
            return LocalizedString.Swap.sellNow
        case .sign:
            return LocalizedString.Confirmation.confirm
        case .deposit:
            return LocalizedString.Deposit.depositNow
        case .interestTransfer:
            return LocalizedString.Transfer.transferNow
        case .withdraw,
             .interestWithdraw:
            return LocalizedString.Withdraw.withdrawNow
        case .receive,
             .viewActivity:
            fatalError("ConfirmationPageContentReducer: \(state.action) not supported.")
        }
    }

    // MARK: - Private methods

    private func setupBitPay(on presenter: DefaultLineItemCellPresenter) {
        let bitPayLogo = UIImage(named: "bitpay-logo")

        presenter.imageWidthRelay.accept(bitPayLogo?.size.width ?? 0)
        presenter.imageRelay.accept(bitPayLogo)
    }
}

extension TransactionConfirmation {
    var isCustom: Bool {
        isErrorNotice || isNotice || isMemo || isBitPay || isCheckbox
    }

    var isCheckbox: Bool {
        switch self {
        case .termsOfService,
             .transferAgreement:
            return true
        default:
            return false
        }
    }

    var isImageNotice: Bool {
        switch self {
        case .imageNotice:
            return true
        default:
            return false
        }
    }

    var isBitPay: Bool {
        switch self {
        case .bitpayCountdown:
            return true
        default:
            return false
        }
    }

    var isNotice: Bool {
        switch self {
        case .notice:
            return true
        default:
            return false
        }
    }

    var isErrorNotice: Bool {
        switch self {
        case .errorNotice:
            return true
        default:
            return false
        }
    }

    var isRequiredAgreement: Bool {
        isTermsOfService && isTransferAgreement
    }

    var isTermsOfService: Bool {
        switch self {
        case .termsOfService:
            return true
        default:
            return false
        }
    }

    var isTransferAgreement: Bool {
        switch self {
        case .transferAgreement:
            return true
        default:
            return false
        }
    }

    var isMemo: Bool {
        switch self {
        case .memo:
            return true
        default:
            return false
        }
    }
}
