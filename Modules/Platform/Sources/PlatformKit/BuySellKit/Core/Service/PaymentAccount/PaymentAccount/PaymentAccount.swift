// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Localization
import MoneyKit

/// Protocol describing a PaymentAccount
public protocol PaymentAccountDescribing {

    /// - Returns: A `Payment Account` if the response matches the requiriments, `nil` otherwise.
    init?(response: PaymentAccount)

    /// A identifier for this PaymentAccount.
    var identifier: String { get }

    /// The state in which this PaymentAccount is.
    var state: PaymentAccountProperty.State { get }

    /// The currency for this PaymentAccount.
    var currency: FiatCurrency { get }

    /// An array of fields that fully represent this Payment Account for a human consumer.
    var fields: [PaymentAccountProperty.Field] { get }
}
