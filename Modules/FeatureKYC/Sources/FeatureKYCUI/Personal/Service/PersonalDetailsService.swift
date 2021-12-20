// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import DIKit
import PlatformKit
import RxSwift

final class PersonalDetailsService {

    private let client: KYCClientAPI

    init(client: KYCClientAPI = resolve()) {
        self.client = client
    }

    func update(firstName: String?, lastName: String?, birthday: Date?) -> Completable {
        client.updatePersonalDetails(firstName: firstName, lastName: lastName, birthday: birthday)
            .asObservable()
            .ignoreElements()
            .asCompletable()
    }
}
