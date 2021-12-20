// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Examples
import PlatformUIKit
import RxCocoa
import RxSwift
import SwiftUI
import ToolKit
import UIKit

public enum DebugScreenContext: String, Hashable {
    case tag
}

public protocol DebugCoordinating {
    /// Enables the debug menu which can be activated by shaking the device
    func enableDebugMenu(for window: UIWindow?)

    /// Removes the debug menu from being presented
    func disableDebugMenu()
}

final class DebugCoordinator: NSObject, DebugCoordinating {

    private var disposeBag = DisposeBag()

    private var screenLifetimeBag = DisposeBag()
    private var navigationController: UINavigationController?

    private var isDisplayed = PublishRelay<Bool>()

    private var window: UIWindow?

    func enableDebugMenu(for window: UIWindow?) {
        self.window = window
        guard let window = window else { return }

        let motionEnded = window.rx.motionEnded
            .filter { $0 == .motionShake }
            .share()

        let isDisplayed = motionEnded
            .map(weak: self) { (self, _) -> Bool in
                self.navigationController == nil
            }
            .startWith(true)

        motionEnded
            .withLatestFrom(isDisplayed)
            .filter { $0 }
            .subscribe(onNext: { [weak self, window] _ in
                guard let self = self else { return }
                guard let topViewController = window.rootViewController?.topMostViewController else { return }
                self.showMenu(in: topViewController)
            })
            .disposed(by: disposeBag)
    }

    func disableDebugMenu() {
        disposeBag = DisposeBag()
    }

    private func showMenu(in rootController: UIViewController) {
        let viewModel = DebugViewModel(itemsProvider: DebugItemType.provideAllItems)
        let debugViewController = DebugViewController(viewModel: viewModel)
        debugViewController.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        let navigationController = UINavigationController(rootViewController: debugViewController)
        navigationController.presentationController?.delegate = self
        self.navigationController = navigationController

        viewModel.routeTo
            .subscribe(onNext: { [weak self] effect in
                self?.handle(effect)
            })
            .disposed(by: screenLifetimeBag)

        rootController.present(navigationController, animated: true, completion: nil)
    }

    private func dismissDebugController() {
        navigationController?.dismiss(animated: true, completion: { [weak self] in
            self?.navigationController = nil
            self?.screenLifetimeBag = DisposeBag()
        })
    }

    private func handle(_ effect: DebugViewModel.Effects) {
        switch effect {
        case .route(let type):
            route(to: type)
        case .close:
            dismissDebugController()
        }
    }

    private func route(to type: DebugItemType) {
        switch type {
        case .interalFeatureFlags:
            let viewModel = InternalFeatureFlagViewModel()
            let viewController = InternalFeatureFlagViewController(viewModel: viewModel)
            navigationController?.pushViewController(viewController, animated: true)
        case .componentLibraryExamples:
            let view = Examples.RootView()
            let viewController = UIHostingController(rootView: view)
            navigationController?.pushViewController(viewController, animated: true)
        case .colorScheme:
            guard let window = window else { return }
            switch window.overrideUserInterfaceStyle {
            case .dark:
                window.overrideUserInterfaceStyle = .light
            default:
                window.overrideUserInterfaceStyle = .dark
            }
        }
    }
}

extension DebugCoordinator: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        navigationController = nil
        screenLifetimeBag = DisposeBag()
    }
}

extension Reactive where Base: UIResponder {
    var motionEnded: ControlEvent<UIEvent.EventSubtype> {
        let source = methodInvoked(#selector(UIResponder.motionEnded(_:with:)))
            .map { args -> UIEvent.EventSubtype in
                guard let type = args.first as? Int else {
                    return .none
                }
                return UIEvent.EventSubtype(rawValue: type) ?? .none
            }
        return ControlEvent(events: source)
    }
}
