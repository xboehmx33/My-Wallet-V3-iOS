// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import DIKit
import MoneyKit
import RxSwift
import ToolKit

final class FiatAsset: Asset {

    // MARK: - Private Properties

    private let enabledCurrenciesService: EnabledCurrenciesServiceAPI

    // MARK: - Setup

    init(enabledCurrenciesService: EnabledCurrenciesServiceAPI = resolve()) {
        self.enabledCurrenciesService = enabledCurrenciesService
    }

    // MARK: - Asset

    func accountGroup(filter: AssetFilter) -> AnyPublisher<AccountGroup, Never> {
        switch filter {
        case .all,
             .custodial:
            return custodialGroup
        case .interest,
             .nonCustodial,
             .exchange:
            return .just(FiatAccountGroup(accounts: []))
        }
    }

    func parse(address: String) -> AnyPublisher<ReceiveAddress?, Never> {
        .just(nil)
    }

    // MARK: - Helpers

    private var allAccountsGroup: AnyPublisher<AccountGroup, Never> {
        custodialGroup
    }

    private var custodialGroup: AnyPublisher<AccountGroup, Never> {
        let accounts = enabledCurrenciesService.allEnabledFiatCurrencies
            .map { FiatCustodialAccount(fiatCurrency: $0) }
        return .just(FiatAccountGroup(accounts: accounts))
    }

    /// We cannot transfer for fiat
    func transactionTargets(account: SingleAccount) -> Single<[SingleAccount]> {
        .just([])
    }

    func transactionTargets(
        account: SingleAccount
    ) -> AnyPublisher<[SingleAccount], Never> {
        .just([])
    }
}
