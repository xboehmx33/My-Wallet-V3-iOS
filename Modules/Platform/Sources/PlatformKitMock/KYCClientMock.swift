// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import NabuNetworkError
import NabuNetworkErrorMock
import PlatformKit
import RxSwift
import ToolKit

final class KYCClientMock: KYCClientAPI {

    struct StubbedResults {
        var fetchUser: AnyPublisher<NabuUser, NabuNetworkError> = {
            .failure(NabuNetworkError.mockError)
        }()

        var checkSimplifiedDueDiligenceEligibility: AnyPublisher<SimplifiedDueDiligenceResponse, NabuNetworkError> = {
            .failure(NabuNetworkError.mockError)
        }()

        var checkSimplifiedDueDiligenceVerification: AnyPublisher<SimplifiedDueDiligenceVerificationResponse, NabuNetworkError> = {
            .failure(NabuNetworkError.mockError)
        }()

        var fetchLimitsOverview: AnyPublisher<KYCLimitsOverviewResponse, NabuNetworkError> = {
            .failure(NabuNetworkError.mockError)
        }()
    }

    var stubbedResults = StubbedResults()

    var expectedTiers: Result<KYC.UserTiers, NabuNetworkError>!

    func tiers() -> AnyPublisher<KYC.UserTiers, NabuNetworkError> {
        expectedTiers.publisher.eraseToAnyPublisher()
    }

    var expectedSupportedDocuments: Result<KYCSupportedDocumentsResponse, NabuNetworkError>!

    func supportedDocuments(
        for country: String
    ) -> AnyPublisher<KYCSupportedDocumentsResponse, NabuNetworkError> {
        expectedSupportedDocuments.publisher.eraseToAnyPublisher()
    }

    var expectedUser: Result<NabuUser, NabuNetworkError>!

    func user() -> AnyPublisher<NabuUser, NabuNetworkError> {
        expectedUser.publisher.eraseToAnyPublisher()
    }

    var expectedListOfStates: Result<[KYCState], NabuNetworkError>!

    func listOfStates(
        in country: String
    ) -> AnyPublisher<[KYCState], NabuNetworkError> {
        expectedListOfStates.publisher.eraseToAnyPublisher()
    }

    var expectedSetInitialAddress: AnyPublisher<Void, NabuNetworkError> = {
        .failure(NabuNetworkError.mockError)
    }()

    func setInitialResidentialInfo(
        country: String,
        state: String?
    ) -> AnyPublisher<Void, NabuNetworkError> {
        expectedSetInitialAddress
    }

    var expectedSelectCountry: AnyPublisher<Void, NabuNetworkError>!

    func selectCountry(
        country: String,
        state: String?,
        notifyWhenAvailable: Bool,
        jwtToken: String
    ) -> AnyPublisher<Void, NabuNetworkError> {
        expectedSelectCountry
    }

    var expectedPersonalDetails: AnyPublisher<Void, NabuNetworkError>!

    func updatePersonalDetails(
        firstName: String?,
        lastName: String?,
        birthday: Date?
    ) -> AnyPublisher<Void, NabuNetworkError> {
        expectedPersonalDetails
    }

    var expectedUpdateAddressCompletable: AnyPublisher<Void, NabuNetworkError>!

    func updateAddress(
        userAddress: UserAddress
    ) -> AnyPublisher<Void, NabuNetworkError> {
        expectedUpdateAddressCompletable
    }

    var expectedCredentials: Result<VeriffCredentials, NabuNetworkError>!

    func credentialsForVeriff() -> AnyPublisher<VeriffCredentials, NabuNetworkError> {
        expectedCredentials.publisher.eraseToAnyPublisher()
    }

    var expectedSubmitToVeriffForVerification: AnyPublisher<Void, NabuNetworkError>!

    func submitToVeriffForVerification(
        applicantId: String
    ) -> AnyPublisher<Void, NabuNetworkError> {
        expectedSubmitToVeriffForVerification
    }

    var jwtToken: Result<String, NabuNetworkError>!

    func requestJWT(
        guid: String,
        sharedKey: String
    ) -> AnyPublisher<String, NabuNetworkError> {
        jwtToken.publisher.eraseToAnyPublisher()
    }

    func fetchUser() -> AnyPublisher<NabuUser, NabuNetworkError> {
        stubbedResults.fetchUser
    }

    func checkSimplifiedDueDiligenceEligibility() -> AnyPublisher<SimplifiedDueDiligenceResponse, NabuNetworkError> {
        stubbedResults.checkSimplifiedDueDiligenceEligibility
    }

    func checkSimplifiedDueDiligenceVerification() -> AnyPublisher<SimplifiedDueDiligenceVerificationResponse, NabuNetworkError> {
        stubbedResults.checkSimplifiedDueDiligenceVerification
    }

    func fetchLimitsOverview() -> AnyPublisher<KYCLimitsOverviewResponse, NabuNetworkError> {
        stubbedResults.fetchLimitsOverview
    }
}
