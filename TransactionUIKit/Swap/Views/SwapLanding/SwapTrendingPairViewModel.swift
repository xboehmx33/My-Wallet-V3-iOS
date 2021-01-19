//
//  SwapTrendingPairViewModel.swift
//  TransactionUIKit
//
//  Created by Alex McGregor on 12/21/20.
//  Copyright © 2020 Blockchain Luxembourg S.A. All rights reserved.
//

import Localization
import PlatformKit
import PlatformUIKit

struct SwapTrendingPairViewModel {
    let titleLabel: LabelContent
    let subtitleLabel: LabelContent
    let trendingPair: SwapTrendingPair
    
    var sourceAccount: CryptoAccount {
        trendingPair.sourceAccount
    }
    
    var destinationAccount: CryptoAccount {
        trendingPair.destinationAccount
    }
    
    init(trendingPair: SwapTrendingPair) {
        self.trendingPair = trendingPair
        self.titleLabel = .init(
            text: "\(LocalizationConstants.Swap.swap) \(trendingPair.sourceAccount.currencyType.name)",
            font: .main(.semibold, 16.0),
            color: .textFieldText,
            alignment: .left,
            accessibility: .none
        )
        
        self.subtitleLabel = .init(
            text: "\(LocalizationConstants.Swap.receive) \(trendingPair.destinationAccount.currencyType.name)",
            font: .main(.medium, 14.0),
            color: .descriptionText,
            alignment: .left,
            accessibility: .none
        )
    }
}
