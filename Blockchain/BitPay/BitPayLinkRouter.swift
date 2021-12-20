// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import DIKit
import PlatformKit
import PlatformUIKit
import RxSwift

class BitPayLinkRouter: DeepLinkRouting {

    // MARK: - Private Properties

    private let service: BitpayServiceProtocol

    @LazyInject var tab: TabSwapping
    @LazyInject var coincore: CoincoreAPI

    private let disposeBag = DisposeBag()

    // MARK: - Init

    init(bitpayService: BitpayServiceProtocol = BitpayService.shared) {
        service = bitpayService
    }

    // MARK: - Static Functions

    static func isBitPayURL(_ url: URL) -> Bool {
        url.absoluteString.contains("https://bitpay.com/")
    }

    // MARK: - DeepLinkRouting

    func routeIfNeeded() -> Bool {
        guard let bitpayURL: URL = service.contentRelay.value else { return false }

        let data = bitpayURL.absoluteString
        let asset = coincore[.coin(.bitcoin)]
        let transactionPair = Single.zip(
            BitPayInvoiceTarget.make(from: data, asset: .coin(.bitcoin)),
            asset.defaultAccount.asSingle()
        )
        BitPayInvoiceTarget
            .isBitPay(data)
            .andThen(BitPayInvoiceTarget.isBitcoin(data))
            .andThen(transactionPair)
            .observeOn(MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] target, defaultAccount in
                UIView.animate(
                    withDuration: 0.3,
                    animations: { [weak self] in
                        self?.tab.switchToSend()
                    },
                    completion: { [weak self] _ in
                        self?.tab.send(from: defaultAccount, target: target)
                    }
                )
            })
            .disposed(by: disposeBag)

        service.contentRelay.accept(nil)
        return true
    }
}
