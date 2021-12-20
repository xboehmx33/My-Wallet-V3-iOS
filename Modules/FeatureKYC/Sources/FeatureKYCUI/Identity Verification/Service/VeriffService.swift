// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import DIKit
import PlatformKit
import RxSwift

final class VeriffService {

    private let client: KYCClientAPI

    init(client: KYCClientAPI = resolve()) {
        self.client = client
    }

    /// Creates VeriffCredentials
    func createCredentials() -> Single<VeriffCredentials> {
        client.credentialsForVeriff()
            .asSingle()
    }

    /// Submits the Veriff applicantId to Blockchain to complete KYC processing.
    /// This should be invoked upon successfully uploading the identity docs to Veriff.
    ///
    /// - Parameter applicantId: applicantId derived from `VeriffCredentials`
    /// - Returns: a Completable
    func submitVerification(applicantId: String) -> Completable {
        client.submitToVeriffForVerification(applicantId: applicantId)
            .asObservable()
            .ignoreElements()
            .asCompletable()
    }
}
