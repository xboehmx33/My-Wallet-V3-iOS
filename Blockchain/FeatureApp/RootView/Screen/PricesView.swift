//  Copyright © 2021 Blockchain Luxembourg S.A. All rights reserved.

import FeatureDashboardUI
import PlatformUIKit
import SwiftUI

struct PricesView: UIViewControllerRepresentable {

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}

    func makeUIViewController(context: Context) -> some UIViewController {
        let viewController = PricesViewController(
            presenter: PricesScreenPresenter(
                drawerRouter: NoDrawer(),
                interactor: PricesScreenInteractor(
                    showSupportedPairsOnly: false
                )
            )
        )
        viewController.automaticallyApplyNavigationBarStyle = false
        return viewController
    }
}

class NoDrawer: DrawerRouting {
    func toggleSideMenu() {}
    func closeSideMenu() {}
}
