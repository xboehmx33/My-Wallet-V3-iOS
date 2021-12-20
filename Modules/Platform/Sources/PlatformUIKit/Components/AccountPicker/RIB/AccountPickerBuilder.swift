// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import DIKit
import Localization
import PlatformKit
import RIBs

public typealias AccountPickerDidSelect = (BlockchainAccount) -> Void

public enum AccountPickerListenerBridge {
    case simple(AccountPickerDidSelect)
    case listener(AccountPickerListener)
}

public protocol AccountPickerBuildable: RIBs.Buildable {

    /// Builder for the Account Picker
    /// - Parameters:
    ///   - listener: Listener for interaction callbacks.
    ///   - navigationModel: Navigation Model for the UINavigationController
    ///   - headerModel: Header Model
    ///   - buttonViewModel: Optional button. (e.g. `+Add New` below a list of banks)
    ///   - showWithdrawalLocks: flags that determines if Withdrawal Lock should be shown
    func build(
        listener: AccountPickerListenerBridge,
        navigationModel: ScreenNavigationModel?,
        headerModel: AccountPickerHeaderType,
        buttonViewModel: ButtonViewModel?,
        showWithdrawalLocks: Bool
    ) -> AccountPickerRouting
}

public protocol AccountPickerListener: AnyObject {
    func didSelectActionButton()
    func didSelect(blockchainAccount: BlockchainAccount)
    func didTapBack()
    func didTapClose()
}

public final class AccountPickerBuilder: AccountPickerBuildable {

    @LazyInject var viewController: AccountPickerViewControllable

    // MARK: - Private Properties

    private let accountProvider: AccountPickerAccountProviding
    private let action: AssetAction

    // MARK: - Init

    public convenience init(
        singleAccountsOnly: Bool,
        action: AssetAction
    ) {
        let provider = AccountPickerAccountProvider(
            singleAccountsOnly: singleAccountsOnly,
            action: action,
            failSequence: false
        )
        self.init(accountProvider: provider, action: action)
    }

    public init(
        accountProvider: AccountPickerAccountProviding,
        action: AssetAction
    ) {
        self.accountProvider = accountProvider
        self.action = action
    }

    // MARK: - Public Methods

    public func build(
        listener: AccountPickerListenerBridge,
        navigationModel: ScreenNavigationModel?,
        headerModel: AccountPickerHeaderType,
        buttonViewModel: ButtonViewModel? = nil,
        showWithdrawalLocks: Bool = false
    ) -> AccountPickerRouting {
        let shouldOverrideNavigationEffects: Bool
        switch listener {
        case .listener:
            shouldOverrideNavigationEffects = true
        case .simple:
            shouldOverrideNavigationEffects = false
        }

        viewController.shouldOverrideNavigationEffects = shouldOverrideNavigationEffects
        let presenter = AccountPickerPresenter(
            viewController: viewController,
            action: action,
            navigationModel: navigationModel,
            headerModel: headerModel,
            buttonViewModel: buttonViewModel,
            showWithdrawalLocks: showWithdrawalLocks
        )
        let interactor = AccountPickerInteractor(
            presenter: presenter,
            accountProvider: accountProvider,
            listener: listener
        )
        return AccountPickerRouter(interactor: interactor, viewController: viewController)
    }
}
