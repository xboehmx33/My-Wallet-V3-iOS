// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import DIKit
import FeatureAuthenticationDomain
import NetworkKit
import PlatformKit
import RxSwift
import ToolKit

class KYCCountrySelectionInteractor {

    private let jwtService: JWTServiceAPI
    private let kycClient: KYCClientAPI

    init(
        jwtService: JWTServiceAPI = resolve(),
        kycClient: KYCClientAPI = resolve()
    ) {
        self.kycClient = kycClient
        self.jwtService = jwtService
    }

    func selected(country: CountryData, shouldBeNotifiedWhenAvailable: Bool? = nil) -> Disposable {
        sendSelection(countryCode: country.code, shouldBeNotifiedWhenAvailable: shouldBeNotifiedWhenAvailable)
    }

    func selected(state: KYCState, shouldBeNotifiedWhenAvailable: Bool? = nil) -> Disposable {
        sendSelection(
            countryCode: state.countryCode,
            state: state.code,
            shouldBeNotifiedWhenAvailable: shouldBeNotifiedWhenAvailable
        )
    }

    private func sendSelection(
        countryCode: String,
        state: String? = nil,
        shouldBeNotifiedWhenAvailable: Bool? = nil
    ) -> Disposable {
        jwtService.token
            .asObservable()
            .take(1)
            .asSingle()
            .flatMapCompletable(weak: self) { (self, jwtToken) -> Completable in
                self.kycClient.selectCountry(
                    country: countryCode,
                    state: state,
                    notifyWhenAvailable: shouldBeNotifiedWhenAvailable ?? false,
                    jwtToken: jwtToken
                )
                .asObservable()
                .ignoreElements()
                .asCompletable()
            }
            .subscribe()
    }
}
