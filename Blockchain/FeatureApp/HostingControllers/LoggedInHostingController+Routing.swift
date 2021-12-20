// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import DIKit
import FeatureAuthenticationUI
import FeatureDashboardUI
import FeatureInterestUI
import FeatureQRCodeScannerData
import FeatureQRCodeScannerDomain
import FeatureQRCodeScannerUI
import FeatureSettingsUI
import FeatureTransactionUI
import FeatureWalletConnectDomain
import MoneyKit
import PlatformKit
import PlatformUIKit
import SwiftUI
import ToolKit

// Provides necessary methods for several protocols and tab swapping
// most, if not all, is copied over from `AppCoordinator`, which was deprecated and removed
extension LoggedInHostingController {

    func handleAirdrops() {
        airdropRouter.presentAirdropCenterScreen()
    }

    func handleSecureChannel() {
        showQRCodeScanner()
    }

    func startBackupFlow() {
        let router: FeatureDashboardUI.BackupRouterAPI = resolve()
        backupRouter = router
        router.start()
    }

    func createAccountsAndAddressesViewController() -> UIViewController {
        let storyboard = UIStoryboard(name: "AccountsAndAddresses", bundle: nil)
        let viewController = storyboard.instantiateViewController(
            withIdentifier: "AccountsAndAddressesNavigationController"
        ) as! AccountsAndAddressesNavigationController
        viewController.modalPresentationStyle = .fullScreen
        viewController.modalTransitionStyle = .coverVertical
        accountsAndAddressesNavigationController = viewController
        return viewController
    }

    func handleAccountsAndAddresses() {
        (topMostViewController ?? self).present(createAccountsAndAddressesViewController(), animated: true)
    }

    func handleInterest() {
        let interestAccountList = InterestAccountListHostingController()
        interestAccountList.delegate = self
        topMostViewController?.present(
            interestAccountList,
            animated: true
        )
    }

    func handleSettings() {
        showSettingsView()
    }

    func handleExchange() {
        guard let tabViewController = tabControllerManager?.tabViewController else { return }
        ExchangeCoordinator.shared.start(from: tabViewController)
    }

    func handleWebLogin() {
        let presenter = WebLoginScreenPresenter()
        let viewController = WebLoginScreenViewController(presenter: presenter)
        let navigationController = UINavigationController(rootViewController: viewController)
        topMostViewController?.present(
            navigationController,
            animated: true
        )
    }

    func handleSupport() {
        Publishers.Zip(
            featureFlagService.isEnabled(.remote(.customerSupportChat)),
            simpleBuyEligiblityService
                .isEligiblePublisher
        )
        .receive(on: DispatchQueue.main)
        .sink(receiveValue: { [weak self] isSupported, isEligible in
            guard let self = self else { return }
            guard isEligible, isSupported else {
                self.showLegacySupportAlert()
                return
            }
            self.showCustomerChatSupportIfSupported()
        })
        .store(in: &cancellables)
    }

    private func showCustomerChatSupportIfSupported() {
        tiersService
            .fetchTiers()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                switch completion {
                case .failure(let error):
                    Logger.shared.error("Error fetching tiers: \(error)")
                    self?.showLegacySupportAlert()
                case .finished:
                    break
                }
            }, receiveValue: { [customerSupportChatRouter] tiers in
                guard tiers.isTier2Approved else {
                    self.showLegacySupportAlert()
                    return
                }
                customerSupportChatRouter.start()
            })
            .store(in: &cancellables)
    }

    private func showLegacySupportAlert() {
        let title = String(format: LocalizationConstants.openArg, Constants.Url.blockchainSupport)
        let alert = UIAlertController(
            title: title,
            message: LocalizationConstants.youWillBeLeavingTheApp,
            preferredStyle: .alert
        )
        alert.addAction(
            UIAlertAction(title: LocalizationConstants.continueString, style: .default) { _ in
                guard let url = URL(string: Constants.Url.blockchainSupport) else { return }
                UIApplication.shared.open(url)
            }
        )
        alert.addAction(
            UIAlertAction(title: LocalizationConstants.cancel, style: .cancel)
        )
        present(alert, animated: true)
    }

    func handleLogout() {
        let alert = UIAlertController(
            title: LocalizationConstants.SideMenu.logout,
            message: LocalizationConstants.SideMenu.logoutConfirm,
            preferredStyle: .alert
        )
        alert.addAction(
            UIAlertAction(title: LocalizationConstants.okString, style: .default) { [weak self] _ in
                self?.viewStore.send(.logout)
            }
        )
        alert.addAction(UIAlertAction(title: LocalizationConstants.cancel, style: .cancel))
        topMostViewController?.present(alert, animated: true)
    }

    /// Starts Buy Crypto flow.
    func handleBuyCrypto(currency: CryptoCurrency = .coin(.bitcoin)) {
        coincore
            .cryptoAccounts(for: currency, supporting: .buy, filter: .custodial)
            .receive(on: DispatchQueue.main)
            .sink { _ in
                // NOOP
            } receiveValue: { [weak self] accounts in
                self?.handleBuyCrypto(account: accounts.first)
            }
            .store(in: &cancellables)
    }

    func handleBuyCrypto(account: CryptoAccount?) {
        let presenter = topMostViewController ?? self
        transactionsAdapter.presentTransactionFlow(to: .buy(account), from: presenter) { result in
            Logger.shared.info("[AppCoordinator] Buy Transaction Flow completed with result '\(result)'")
        }
    }

    /// Starts Sell Crypto flow
    func handleSellCrypto(account: CryptoAccount? = nil) {
        let presenter = topMostViewController ?? self
        transactionsAdapter.presentTransactionFlow(to: .sell(account), from: presenter) { result in
            Logger.shared.info("[AppCoordinator] Sell Transaction Flow completed with result '\(result)'")
        }
    }

    /// Starts Swap Crypto flow
    func handleSwapCrypto(account: CryptoAccount?) {
        let presenter = topMostViewController ?? self
        transactionsAdapter.presentTransactionFlow(to: .swap(account), from: presenter) { result in
            Logger.shared.info("[AppCoordinator] Buy Transaction Flow completed with result '\(result)'")
        }
    }

    func startSimpleBuyAtLogin() {
        handleBuyCrypto()
    }

    func showFundTrasferDetails(fiatCurrency: FiatCurrency, isOriginDeposit: Bool) {
        let stateService = PlatformUIKit.StateService()
        let builder = PlatformUIKit.Builder(
            stateService: stateService
        )

        buyRouter = PlatformUIKit.Router(builder: builder, currency: .coin(.bitcoin))
        buyRouter?.setup(startImmediately: false)
        stateService.showFundsTransferDetails(
            for: fiatCurrency,
            isOriginDeposit: isOriginDeposit
        )
    }

    func showNabuUserConflictErrorIfNeeded(walletIdHint: String) {
        let warningView = UIHostingController(
            rootView: TradingAccountWarningView(
                walletIdHint: walletIdHint
            )
        )
        warningView.isModalInPresentation = true
        warningView.rootView.logoutButtonTapped = { [weak self] in
            guard let self = self else { return }
            self.handleLogout()
        }
        warningView.rootView.cancelButtonTapped = {
            warningView.dismiss(animated: true, completion: nil)
        }
        topMostViewController?.present(warningView, animated: true)
    }

    func showQRCodeScanner() {
        let builder = QRCodeScannerViewControllerBuilder(
            completed: { [weak self] result in
                self?.didCompleteQRCodeScanner(result: result)
            }
        )

        guard let viewController = builder.build() else {
            // No camera access, an alert will be displayed automatically.
            return
        }
        topMostViewController?.present(
            viewController,
            animated: true
        )
    }

    private func didCompleteQRCodeScanner(
        result: Result<QRCodeScannerResultType, QRCodeScannerResultError>
    ) {
        featureFlagService.isEnabled(.remote(.walletConnectEnabled))
            .sink { [weak self] isWalletConnectEnabled in
                switch result {
                case .success(.secureChannel(let message)):
                    self?.secureChannelRouter.didScanPairingQRCode(msg: message)
                case .success(.cryptoTarget(let target)):
                    switch target {
                    case .address(let account, let address):
                        self?.tabControllerManager?.send(from: account, target: address)
                    case .bitpay:
                        break
                    }
                case .success(.walletConnect(let url)):
                    guard isWalletConnectEnabled else {
                        return
                    }
                    self?.walletConnectService.connect(url)
                case .success(.deepLink):
                    break
                case .failure:
                    break
                }
            }
            .store(in: &cancellables)
    }
}
