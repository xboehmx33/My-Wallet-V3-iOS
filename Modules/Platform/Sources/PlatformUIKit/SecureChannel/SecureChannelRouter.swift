// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import DIKit
import Localization
import PlatformKit
import RxSwift
import ToolKit

public protocol SecureChannelRouting {
    func didScanPairingQRCode(msg: String)
    func didReceiveSecureChannelCandidate(_ candidate: SecureChannelConnectionCandidate)
    func didReceiveError(_ error: SecureChannelError)
}

final class SecureChannelRouter: SecureChannelRouting {

    private typealias LocalizedString = LocalizationConstants.SecureChannel.Alert

    private let service: SecureChannelAPI
    private let topMostViewControllerProvider: TopMostViewControllerProviding
    private let loadingViewPresenter: LoadingViewPresenting
    private let alertViewPresenter: AlertViewPresenterAPI
    private var disposeBag = DisposeBag()
    private let store = SecureChannelCandidateStore()
    private weak var nav: UINavigationController?

    init(
        service: SecureChannelAPI = resolve(),
        loadingViewPresenter: LoadingViewPresenting = resolve(),
        alertViewPresenter: AlertViewPresenterAPI = resolve(),
        topMostViewControllerProvider: TopMostViewControllerProviding = resolve()
    ) {
        self.service = service
        self.loadingViewPresenter = loadingViewPresenter
        self.alertViewPresenter = alertViewPresenter
        self.topMostViewControllerProvider = topMostViewControllerProvider

        NotificationCenter.when(.login) { [weak self] _ in
            self?.didLogin()
        }
    }

    private func didLogin() {
        guard let candidate = store.retrieve() else {
            return
        }
        didReceiveSecureChannelCandidate(candidate)
    }

    func didScanPairingQRCode(msg: String) {
        service.onQRCodeScanned(msg: msg)
            .subscribe()
            .disposed(by: disposeBag)
    }

    private func didRejectSecureChannel(to details: SecureChannelConnectionDetails) {
        service.didRejectSecureChannel(details: details)
            .handleLoaderForLifecycle(loader: loadingViewPresenter)
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(
                onCompleted: { [weak self] in
                    self?.showResultScreen(state: .denied)
                },
                onError: { [weak self] _ in
                    self?.showResultScreen(state: .error)
                }
            )
            .disposed(by: disposeBag)
    }

    private func didAcceptSecureChannel(to details: SecureChannelConnectionDetails) {
        service
            .didAcceptSecureChannel(details: details)
            .handleLoaderForLifecycle(loader: loadingViewPresenter)
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(
                onCompleted: { [weak self] in
                    self?.showResultScreen(state: .approved)
                },
                onError: { [weak self] _ in
                    self?.showResultScreen(state: .error)
                }
            )
            .disposed(by: disposeBag)
    }

    func didReceiveSecureChannelCandidate(_ candidate: SecureChannelConnectionCandidate) {
        service.isReadyForSecureChannel()
            .catchErrorJustReturn(false)
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(
                onSuccess: { [weak self] isReadyForSecureChannel in
                    self?.didReceiveSecureChannelCandidate(candidate, isReadyForSecureChannel: isReadyForSecureChannel)
                }
            )
            .disposed(by: disposeBag)
    }

    private func didReceiveSecureChannelCandidate(
        _ candidate: SecureChannelConnectionCandidate,
        isReadyForSecureChannel: Bool
    ) {
        guard isReadyForSecureChannel else {
            store.store(candidate)
            showNeedLoginAlert()
            return
        }

        guard nav == nil else {
            return
        }

        showDetailsScreen(with: candidate)
    }

    func didReceiveError(_ error: SecureChannelError) {
        alertViewPresenter.notify(
            content: AlertViewContent(
                title: LocalizedString.title,
                message: error.errorDescription
            ),
            in: nil
        )
    }

    private func showNeedLoginAlert() {
        alertViewPresenter.notify(
            content: AlertViewContent(
                title: LocalizedString.title,
                message: LocalizedString.loginRequired
            ),
            in: nil
        )
    }

    private func showResultScreen(state: SecureChannelResultPresenter.State) {
        let presenter = SecureChannelResultPresenter(state: state) { [weak self] in
            self?.nav?.dismiss(animated: true)
        }
        let vc = PendingStateViewController(presenter: presenter)
        nav?.pushViewController(vc, animated: true)
    }

    private func showDetailsScreen(with candidate: SecureChannelConnectionCandidate) {
        let presenter = SecureChannelDetailsPresenter(
            candidate: candidate,
            didAcceptSecureChannel: { [weak self] didApproved in
                if didApproved {
                    self?.didAcceptSecureChannel(to: candidate.details)
                } else {
                    self?.didRejectSecureChannel(to: candidate.details)
                }
            }
        )
        let root = DetailsScreenViewController(presenter: presenter)
        let nav = UINavigationController(rootViewController: root)
        self.nav = nav
        present(viewController: nav)
    }

    private func present(viewController: UIViewController) {
        guard let topMostViewController = topMostViewControllerProvider.topMostViewController else {
            return
        }
        let base = topMostViewController.presentedViewController ?? topMostViewController
        base.present(viewController, animated: true, completion: nil)
    }
}
