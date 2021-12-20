//  Copyright © 2021 Blockchain Luxembourg S.A. All rights reserved.

import FeatureActivityUI
import SwiftUI

struct ActivityView: UIViewControllerRepresentable {

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}

    func makeUIViewController(context: Context) -> some UIViewController {
        let viewController = ActivityScreenViewController(drawerRouting: NoDrawer())
        viewController.automaticallyApplyNavigationBarStyle = false
        return viewController
    }
}
