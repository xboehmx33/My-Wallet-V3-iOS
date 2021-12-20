// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import MoneyKit
import PlatformKit
import UIComponentsKit

extension PaymentMethod {

    public var logoResource: UIComponentsKit.ImageResource {
        switch type {
        case .card:
            return .local(name: "icon-card", bundle: .platformUIKit)

        case .bankAccount, .bankTransfer:
            return .local(name: "icon-bank", bundle: .platformUIKit)

        case .funds(let currency):
            return currency.logoResource
        }
    }
}

extension PaymentMethodAccount {

    // This extension overrides the default implementation of `BlockchainAccount`
    public var logoResource: UIComponentsKit.ImageResource {
        switch paymentMethodType {
        case .card(let cardData):
            return cardData.type.thumbnail ?? .local(name: "icon-card", bundle: .platformUIKit)

        case .linkedBank:
            return .local(name: "icon-bank", bundle: .platformUIKit)

        case .account(let fundData):
            return fundData.balance.currency.logoResource

        case .suggested(let paymentMethod):
            return paymentMethod.logoResource
        }
    }

    // This extension overrides the default implementation of `BlockchainAccount`
    public var logoBackgroundColor: UIColor {
        switch paymentMethodType {
        case .account:
            return .fiat

        case .card,
             .suggested:
            return .background

        case .linkedBank:
            return .clear
        }
    }
}
