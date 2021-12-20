// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import AnalyticsKit
import MoneyKit
import PlatformKit

extension AnalyticsEvents {

    // MARK: - Request flow

    public enum Request: AnalyticsEvent {
        case requestTabItemClick
        case requestQrAddressClick(asset: CryptoCurrency)
        case requestRequestPaymentClick(asset: CryptoCurrency)

        public var name: String {
            switch self {
            // Request - tab item click
            case .requestTabItemClick:
                return "request_tab_item_click"
            // Request - QR address clicked
            case .requestQrAddressClick:
                return "request_qr_address_click"
            // Request - request payment clicked
            case .requestRequestPaymentClick:
                return "request_request_payment_click"
            }
        }

        public var params: [String: String]? {
            nil
        }
    }
}
