// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import DIKit
import MoneyKit
import PlatformKit
import RIBs
import RxCocoa
import RxSwift

protocol LinkedBanksSelectionRouting: AnyObject {
    func addNewBank()
    func dismissAddNewBank()
}

protocol LinkedBanksSelectionListener: AnyObject {
    func bankSelected(beneficiary: Beneficiary)
    func closeFlow()
}

enum LinkedBanksSelectionAction: Equatable {
    case items([LinkedBanksSectionModel])
}

protocol LinkedBanksSelectionPresentable: Presentable {
    func connect(action: Driver<LinkedBanksSelectionAction>) -> Driver<LinkedBanksSelectionEffects>
}

final class LinkedBanksSelectionInteractor: PresentableInteractor<LinkedBanksSelectionPresentable>,
    LinkedBanksSelectionInteractable,
    AddNewBankAccountListener
{

    weak var router: LinkedBanksSelectionRouting?
    weak var listener: LinkedBanksSelectionListener?

    private let beneficiariesService: BeneficiariesServiceAPI
    private let currency: FiatCurrency

    init(
        presenter: LinkedBanksSelectionPresentable,
        currency: FiatCurrency,
        beneficiariesService: BeneficiariesServiceAPI = resolve()
    ) {
        self.beneficiariesService = beneficiariesService
        self.currency = currency
        super.init(presenter: presenter)
    }

    override func didBecomeActive() {
        super.didBecomeActive()

        let sections = beneficiariesService.beneficiaries
            .map { [currency] beneficiaries in
                beneficiaries.filter { $0.currency == currency }
            }
            .map { [currency] beneficiariesFiltered -> [LinkedBanksSectionItem] in
                let beneficiariesViewModels = beneficiariesFiltered.map(BeneficiaryLinkedBankViewModel.init(data:))
                let beneficiariesItems = beneficiariesViewModels.map(LinkedBanksSectionItem.linkedBank)
                // always append `.addNewBank` in the list
                let item = LinkedBanksSectionItem.addNewBank(AddBankCellModel(fiatCurrency: currency))
                return beneficiariesItems + [item]
            }
            .map { items in
                [LinkedBanksSectionModel(items: items)]
            }

        let items = sections
            .map { LinkedBanksSelectionAction.items($0) }
            .asDriverCatchError()

        let actions = Driver.merge(items)
        presenter.connect(action: actions)
            .drive(onNext: handleEffects)
            .disposeOnDeactivate(interactor: self)
    }

    override func willResignActive() {
        super.willResignActive()
    }

    func handleEffects(_ effect: LinkedBanksSelectionEffects) {
        switch effect {
        case .selection(let item):
            handle(selection: item)
        case .closeFlow:
            listener?.closeFlow()
        case .none:
            break
        }
    }

    private func handle(selection item: LinkedBanksSectionItem) {
        switch item {
        case .linkedBank(let viewModel):
            listener?.bankSelected(beneficiary: viewModel.data)
        case .addNewBank:
            router?.addNewBank()
        }
    }

    func dismissAddNewBankAccount() {
        router?.dismissAddNewBank()
    }
}
