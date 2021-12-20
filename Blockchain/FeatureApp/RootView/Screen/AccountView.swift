//  Copyright © 2021 Blockchain Luxembourg S.A. All rights reserved.

import DIKit
import FeatureSettingsUI
import SwiftUI

struct AccountView: UIViewControllerRepresentable {

    let router: SettingsRouterAPI = resolve()
    let navigationController = UINavigationController()

    func makeUIViewController(context: Context) -> some UIViewController {
        let viewController = router.makeViewController()
        viewController.automaticallyApplyNavigationBarStyle = false
        viewController.navigationItem.backButtonDisplayMode = .minimal
        navigationController.viewControllers = [viewController]
        router.navigationRouter.navigationControllerAPI = navigationController
        return navigationController
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
}
