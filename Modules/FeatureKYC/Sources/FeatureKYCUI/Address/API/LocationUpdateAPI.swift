// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import DIKit
import PlatformKit
import RxSwift

final class LocationUpdateService {
    private let client: KYCClientAPI

    init(client: KYCClientAPI = resolve()) {
        self.client = client
    }

    func update(address: UserAddress) -> Completable {
        client.updateAddress(userAddress: address)
            .asObservable()
            .ignoreElements()
            .asCompletable()
    }
}
