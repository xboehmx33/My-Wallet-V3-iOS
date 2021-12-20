//
//  BlockchainNameResolutionService.swift
//  FeatureActivityDomain
//
//  Created by Paulo on 27/04/2021.
//  Copyright © 2021 Blockchain Luxembourg S.A. All rights reserved.
//

import Combine
import DIKit
import MoneyKit
import PlatformKit

public protocol BlockchainNameResolutionServiceAPI {

    func validate(
        domainName: String,
        currency: CryptoCurrency
    ) -> AnyPublisher<ReceiveAddress?, Never>
}

final class BlockchainNameResolutionService: BlockchainNameResolutionServiceAPI {

    private let repository: BlockchainNameResolutionRepositoryAPI
    private let factory: ExternalAssetAddressServiceAPI

    init(
        repository: BlockchainNameResolutionRepositoryAPI = resolve(),
        factory: ExternalAssetAddressServiceAPI = resolve()
    ) {
        self.repository = repository
        self.factory = factory
    }

    func validate(
        domainName: String,
        currency: CryptoCurrency
    ) -> AnyPublisher<ReceiveAddress?, Never> {
        guard preValidate(domainName: domainName) else {
            return .just(nil)
        }
        return repository
            .resolve(domainName: domainName, currency: currency.code.lowercased())
            .eraseError()
            .flatMap { [factory] response -> AnyPublisher<ReceiveAddress?, Error> in
                factory
                    .makeExternalAssetAddress(
                        asset: currency,
                        address: response.address,
                        label: domainName,
                        onTxCompleted: { _ in .empty() }
                    )
                    .map { $0 as ReceiveAddress }
                    .publisher
                    .eraseToAnyPublisher()
                    .eraseError()
            }
            .replaceError(with: nil)
            .eraseToAnyPublisher()
    }

    private func preValidate(domainName: String) -> Bool {
        let components = domainName.components(separatedBy: ".")
        guard components.count == 2 else {
            return false
        }
        guard !components[0].isEmpty else {
            return false
        }
        guard !components[1].isEmpty else {
            return false
        }
        return true
    }
}
