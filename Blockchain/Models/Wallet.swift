// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import DIKit
import MoneyKit
import NetworkKit
import PlatformKit
import PlatformUIKit
import RxSwift
import ToolKit
import WalletPayloadKit

enum WalletJavaScriptError: Error {
    case typeError(message: String, stack: String)
}

extension Wallet {
    @objc func logJavaScriptTypeError(_ message: String, stack: String?) {
        let messageRecorder: MessageRecording = resolve()
        let errorRecorder: ErrorRecording = resolve()
        let stack = stack ?? ""
        messageRecorder.record("JS Stack: '\(stack)'")
        messageRecorder.record("JS Error: '\(message)'")
        errorRecorder.error(WalletJavaScriptError.typeError(message: message, stack: stack))
    }

    /// Updates an account label.
    /// - Parameters:
    ///   - label: The new account name.
    ///   - cryptoCurrency: The CryptoCurrency of the account you want to update.
    ///   - index: The derivation index of the account you want to update.
    func updateAccountLabel(
        _ cryptoCurrency: NonCustodialCoinCode,
        index: Int,
        label: String
    ) -> Completable {
        Completable.create(weak: self) { (self, observer) -> Disposable in
            self.updateLabel(label, for: cryptoCurrency, index: index)
            observer(.completed)
            return Disposables.create()
        }
        .subscribeOn(MainScheduler.asyncInstance)
    }

    /// Updates an account label.
    /// - Parameters:
    ///   - label: The new account name.
    ///   - cryptoCurrency: The CryptoCurrency of the account you want to update.
    ///   - index: The derivation index of the account you want to update.
    private func updateLabel(_ label: String, for cryptoCurrency: NonCustodialCoinCode, index: Int) {
        guard isInitialized() else {
            return
        }
        switch cryptoCurrency {
        case .bitcoin:
            isSyncing = true
            context.evaluateScriptCheckIsOnMainQueue("MyWalletPhone.setLabelForAccount(\(index), \"\(label)\")")
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(didSetLabelForAccount),
                name: Constants.NotificationKeys.backupSuccess,
                object: nil
            )
        case .bitcoinCash:
            context.evaluateScriptCheckIsOnMainQueue("MyWalletPhone.bch.setLabelForAccount(\(index), \"\(label)\")")
            getHistory()
        case .stellar:
            context.evaluateScriptCheckIsOnMainQueue("MyWallet.wallet.xlm.accounts[\(index)].label = \"\(label)\"")
            getHistory()
        case .ethereum:
            context.evaluateScriptCheckIsOnMainQueue("MyWallet.wallet.eth.accounts[\(index)].label = \"\(label)\"")
            getHistory()
        }
    }

    @objc func setLabelForAccount(_ index: Int, label: String, assetType: LegacyAssetType) {
        guard Reachability.hasInternetConnection() else {
            AlertViewPresenter.shared.internetConnection()
            return
        }
        updateLabel(label, for: assetType.nonCustodialCoinCode, index: index)
    }

    @objc func didSetLabelForAccount() {
        NotificationCenter.default.removeObserver(
            self,
            name: Constants.NotificationKeys.backupSuccess,
            object: nil
        )
        getHistory()
    }

    @objc func useDebugSettingsIfSet() {
        updateServerURL(BlockchainAPI.shared.walletUrl)
        updateAPIURL(BlockchainAPI.shared.apiUrl)
    }

    private func updateServerURL(_ newURL: String) {
        context
            .evaluateScriptCheckIsOnMainQueue("MyWalletPhone.updateServerURL(\"\(newURL.escapedForJS())\")")
    }

    private func updateAPIURL(_ newURL: String) {
        context
            .evaluateScriptCheckIsOnMainQueue("MyWalletPhone.updateAPIURL(\"\(newURL.escapedForJS())\")")
    }
}

extension Wallet {

    /// If the wallet was already upgraded to V4.
    @objc var didUpgradeToV4: Bool {
        guard isInitialized() else {
            return false
        }
        return context.evaluateScriptCheckIsOnMainQueue("MyWallet.wallet.isUpgradedToV4")?.toBool() ?? false
    }
}
