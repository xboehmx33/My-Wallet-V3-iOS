//
//  CurrencyViewPresenter.swift
//  Copyright © 2021 Blockchain Luxembourg S.A. All rights reserved.
//

import MoneyKit
import RxCocoa

/// An abstract class that doesn't do much: it's only used for communication across modules
open class CurrencyViewPresenter: Equatable {

    /// Required to initialize subsclasses
    public init() {}

    public static func == (lhs: CurrencyViewPresenter, rhs: CurrencyViewPresenter) -> Bool {
        lhs === rhs
    }

    /// Override me. Defailt implementation returns nil.
    open var tap: Signal<CurrencyType>? {
        nil
    }
}
