//  Copyright © 2021 Blockchain Luxembourg S.A. All rights reserved.

#if canImport(SharedComponentLibrary)
import SharedComponentLibrary
#else
import ComponentLibrary
#endif
import DIKit
import FeatureQRCodeScannerDomain
import FeatureQRCodeScannerUI
import FeatureTransactionUI
import FeatureWalletConnectDomain
import Localization
import PlatformUIKit
import SwiftUI
import ToolKit

struct QRCodeScannerView: UIViewControllerRepresentable {

    var secureChannelRouter: SecureChannelRouting = resolve()
    var walletConnectService: WalletConnectServiceAPI = resolve()
    var tabSwapping: TabSwapping = resolve()

    func makeUIViewController(context: Context) -> some UIViewController {

        let builder = QRCodeScannerViewControllerBuilder(
            completed: { result in
                guard case .success(let success) = result else {
                    return
                }

                switch success {
                case .secureChannel(let message):
                    self.secureChannelRouter.didScanPairingQRCode(msg: message)
                case .cryptoTarget(let target):
                    switch target {
                    case .address(let account, let address):
                        self.tabSwapping.send(from: account, target: address)
                    case .bitpay:
                        break
                    }
                case .walletConnect(let url):
                    self.walletConnectService.connect(url)
                case .deepLink:
                    break
                }
            }
        )

        guard let viewController = builder.build() else {
            return UIHostingController(
                rootView: PrimaryNavigationView {
                    ActionableView(
                        .init(
                            media: .image(named: "circular-error-icon"),
                            title: LocalizationConstants.noCameraAccessTitle,
                            subtitle: LocalizationConstants.noCameraAccessMessage
                        ),
                        in: .platformUIKit
                    )
                    .primaryNavigation(title: LocalizationConstants.scanQRCode) {
                        IconButton(icon: .closeCirclev2) {
                            context.environment.presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
            ) as UIViewController
        }

        return viewController as UIViewController
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
}
