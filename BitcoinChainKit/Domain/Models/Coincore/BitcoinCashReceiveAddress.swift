//
//  BitcoinCashReceiveAddress.swift
//  BitcoinChainKit
//
//  Created by Paulo on 24/08/2020.
//  Copyright © 2020 Blockchain Luxembourg S.A. All rights reserved.
//

import PlatformKit
import RxSwift

struct BitcoinCashReceiveAddress: CryptoReceiveAddress, CryptoAssetQRMetadataProviding {
    
    typealias TxCompleted = (TransactionResult) -> Completable
    
    let asset: CryptoCurrency = .bitcoinCash
    let address: String
    let label: String
    let onTxCompleted: TxCompleted
    
    init(address: String, label: String, onTxCompleted: @escaping TxCompleted) {
        self.address = address
        self.label = label
        self.onTxCompleted = onTxCompleted
    }

    var metadata: CryptoAssetQRMetadata {
        BitcoinCashURLPayload(address: address, amount: nil, includeScheme: true)
    }
}
