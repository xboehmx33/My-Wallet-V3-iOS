// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Localization
import MoneyKit
import PlatformKit
import RIBs
import RxCocoa
import RxSwift

final class WithdrawalConfirmationPresenter: RibBridgePresenter, PendingStatePresenterAPI {

    private typealias LocalizedString = LocalizationConstants.FiatWithdrawal.Checkout.ConfirmationScreen

    // MARK: - Properties

    var viewModel: Driver<PendingStateViewModel> = .empty()

    // MARK: - Private Properties

    private weak var routing: WithdrawalConfirmationRouting?
    private let interactor: WithdrawalConfirmationInteractor
    private let disposeBag = DisposeBag()

    init(interactor: WithdrawalConfirmationInteractor, routing: WithdrawalConfirmationRouting) {
        self.interactor = interactor
        self.routing = routing
        super.init(interactable: interactor)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let buttonModel = ButtonViewModel.primary(with: LocalizedString.button)
        buttonModel.tap
            .emit(weak: self) { (self, _) in
                self.routing?.confirmationRequested(to: .closeFlow)
            }
            .disposed(by: disposeBag)

        viewModel = Driver.deferred { [interactor] () -> Driver<PendingStateViewModel> in
            guard let amount = interactor.amount, interactor.isSuccess || interactor.isLoading else {
                return .just(Self.errorViewModel(
                    with: interactor.currencyType,
                    buttonModel: buttonModel,
                    errorDescription: interactor.errorDescription
                ))
            }
            if interactor.isSuccess {
                return .just(Self.viewModel(with: amount, buttonModel: buttonModel))
            }
            return .just(Self.loadingViewModel(with: amount))
        }
    }

    // MARK: - View Model Providers

    private static func loadingViewModel(with amount: FiatValue) -> PendingStateViewModel {
        PendingStateViewModel(
            compositeStatusViewType:
            .composite(
                .init(
                    baseViewType: .text(amount.displaySymbol),
                    sideViewAttributes: .init(type: .loader, position: .rightCorner),
                    backgroundColor: .fiat,
                    cornerRadiusRatio: 0.2
                )
            ),
            title: String(format: LocalizedString.Loading.titlePrefix, amount.toDisplayString(includeSymbol: true)),
            subtitle: LocalizedString.Loading.subtitle
        )
    }

    private static func viewModel(with amount: FiatValue, buttonModel: ButtonViewModel) -> PendingStateViewModel {
        PendingStateViewModel(
            compositeStatusViewType: .composite(
                .init(
                    baseViewType: .text(amount.displaySymbol),
                    sideViewAttributes: .init(
                        type: .image(PendingStateViewModel.Image.success.imageResource),
                        position: .radiusDistanceFromCenter
                    ),
                    backgroundColor: .fiat,
                    cornerRadiusRatio: 0.2
                )
            ),
            title: String(format: LocalizedString.Success.titleSuffix, amount.toDisplayString(includeSymbol: true)),
            subtitle: LocalizedString.Success.subtitle,
            button: buttonModel
        )
    }

    private static func errorViewModel(
        with currencyType: CurrencyType,
        buttonModel: ButtonViewModel,
        errorDescription: String?
    ) -> PendingStateViewModel {
        PendingStateViewModel(
            compositeStatusViewType: .composite(
                .init(
                    baseViewType: .text(currencyType.displaySymbol),
                    sideViewAttributes: .init(type: .image(PendingStateViewModel.Image.circleError.imageResource), position: .rightCorner),
                    backgroundColor: .fiat,
                    cornerRadiusRatio: 0.2
                )
            ),
            title: LocalizedString.Error.titleSuffix,
            subtitle: [LocalizedString.Error.subtitle, errorDescription].compactMap { $0 }.joined(separator: "\n\n"),
            button: buttonModel
        )
    }
}
