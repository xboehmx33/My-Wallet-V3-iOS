// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import DIKit
import NetworkKit
import RxRelay
import RxSwift

class WalletService: WalletOptionsAPI {

    // MARK: - Private Properties

    private(set) var cachedWalletOptions = BehaviorRelay<WalletOptions?>(value: nil)

    private var networkFetchedWalletOptions: Single<WalletOptions> {
        let url = URL(string: BlockchainAPI.shared.walletOptionsUrl)!
        return networkAdapter
            .perform(request: NetworkRequest(endpoint: url, method: .get))
            .asSingle()
            .do(onSuccess: { [weak self] in
                self?.cachedWalletOptions.accept($0)
            })
    }

    private let networkAdapter: NetworkAdapterAPI

    // MARK: - Public

    init(networkAdapter: NetworkAdapterAPI = resolve()) {
        self.networkAdapter = networkAdapter
    }

    /// A Single returning the WalletOptions which contains dynamic flags for configuring the app.
    /// If WalletOptions has already been fetched, this property will return the cached value
    var walletOptions: Single<WalletOptions> {
        Single.deferred { [unowned self] in
            guard let cachedValue = self.cachedWalletOptions.value else {
                return self.networkFetchedWalletOptions
            }
            return Single.just(cachedValue)
        }
    }

    var serverUnderMaintenanceMessage: Single<String?> {
        walletOptions.map { options in
            if options.downForMaintenance {
                // TODO:
                return options.mobileInfo?.message ?? ""
            } else {
                return nil
            }
        }
        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
    }

    // TODO: Re-enable this once we have isolated the source of the crash
//    // TODO: Dimitris - Move this to its own service
//    var serverStatus: Single<ServerIncidents> {
//        let url = URL(string: "https://www.blockchain-status.com/api/v2/incidents.json")!
//        let request = NetworkRequest(endpoint: url, method: .get, authenticated: false)
//        return networkAdapter.perform(request: request)
//    }
}
