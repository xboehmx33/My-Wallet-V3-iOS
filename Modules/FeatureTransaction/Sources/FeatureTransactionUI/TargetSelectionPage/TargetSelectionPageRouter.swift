// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import DIKit
import FeatureTransactionDomain
import MoneyKit
import PlatformKit
import PlatformUIKit
import RIBs

protocol TargetSelectionPageInteractable: Interactable {
    var router: TargetSelectionPageRouting? { get set }
    var listener: TargetSelectionPageListener? { get set }
}

public protocol QRCodeScannerLinkerAPI {
    func presentQRCodeScanner(
        account: CryptoAccount,
        completion: @escaping ((Result<CryptoTargetQRCodeParserTarget, Error>) -> Void)
    )
}

final class TargetSelectionPageRouter: ViewableRouter<TargetSelectionPageInteractable, TargetSelectionPageViewControllable>,
    TargetSelectionPageRouting
{
    let qrCodeScannerLinker: QRCodeScannerLinkerAPI

    init(
        interactor: TargetSelectionPageInteractable,
        viewController: TargetSelectionPageViewControllable,
        qrCodeScannerLinker: QRCodeScannerLinkerAPI = resolve()
    ) {
        self.qrCodeScannerLinker = qrCodeScannerLinker
        super.init(interactor: interactor, viewController: viewController)
        interactor.router = self
    }

    func presentQRScanner(
        sourceAccount: CryptoAccount,
        model: TargetSelectionPageModel
    ) {
        qrCodeScannerLinker
            .presentQRCodeScanner(account: sourceAccount) { result in
                model.process(action: .returnToPreviousStep)
                switch result {
                case .success(.address(let cryptoReceiveAddress)):
                    // We need to validate the address as if it were a
                    // value provided by user entry in the text field.
                    model.process(action: .validateQRScanner(cryptoReceiveAddress))
                case .success(.bitpay(let value)):
                    model.process(action: .validateBitPayPayload(value, sourceAccount.asset))
                case .failure:
                    break
                }
            }
    }
}
