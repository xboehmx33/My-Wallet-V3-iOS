// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import DIKit
import EthereumKit
import MoneyKit
import PlatformKit
import RxSwift
import ToolKit

protocol ERC20HistoricalTransactionServiceAPI: AnyObject {

    func transactions(
        erc20Asset: AssetModel,
        address: EthereumAddress
    ) -> Single<[ERC20HistoricalTransaction]>
}

final class ERC20HistoricalTransactionService: ERC20HistoricalTransactionServiceAPI {

    private enum ServiceError: Error {
        case errorFetchingDetails
    }

    private struct Key: Hashable {
        let erc20Asset: AssetModel
        let address: EthereumAddress
    }

    private let accountClient: ERC20AccountAPIClientAPI
    private let cache: Cache<Key, [ERC20HistoricalTransaction]>

    init(accountClient: ERC20AccountAPIClientAPI = resolve()) {
        self.accountClient = accountClient
        cache = .init(entryLifetime: 60)
    }

    func transactions(
        erc20Asset: AssetModel,
        address: EthereumAddress
    ) -> Single<[ERC20HistoricalTransaction]> {
        guard let contractAddress = erc20Asset.contractAddress?.publicKey else {
            return .just([])
        }
        let key = Key(erc20Asset: erc20Asset, address: address)
        if let response = cache.value(forKey: key) {
            return .just(response)
        }
        return accountClient
            .fetchTransactions(
                from: address.publicKey,
                page: nil,
                contractAddress: contractAddress
            )
            .map(\.transfers)
            .map { transfers in
                transfers.map { item in
                    ERC20HistoricalTransaction(
                        response: item,
                        cryptoCurrency: .erc20(erc20Asset),
                        source: address
                    )
                }
            }
            .asSingle()
            .do(onSuccess: { [cache] response in
                cache.set(response, forKey: key)
            })
    }
}
