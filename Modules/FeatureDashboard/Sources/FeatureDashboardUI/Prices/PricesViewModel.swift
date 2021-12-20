// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Foundation
import MoneyKit
import PlatformKit
import PlatformUIKit
import RxDataSources

enum PricesCellType: Hashable, IdentifiableType {

    case emptyState(LabelContent)
    case currency(CryptoCurrency, () -> PricesTableViewCellPresenter)

    var identity: String {
        switch self {
        case .emptyState:
            return "emptyState"
        case .currency(let cryptoCurrency, _):
            return cryptoCurrency.code
        }
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(identity)
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.identity == rhs.identity
    }
}

struct PricesViewModel: AnimatableSectionModelType {

    // MARK: - Types

    typealias Item = PricesCellType
    typealias Identity = String

    // MARK: - Properties

    let items: [Item]
    var identity: Identity {
        "PricesViewModel"
    }

    // MARK: - Init

    init(original: PricesViewModel, items: [Item]) {
        self.items = items
    }

    init(items: [Item]) {
        self.items = items
    }
}
