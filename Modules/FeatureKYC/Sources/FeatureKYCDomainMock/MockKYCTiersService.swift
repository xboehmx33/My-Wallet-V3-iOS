// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import PlatformKit
import RxSwift

final class MockKYCTiersService: PlatformKit.KYCTiersServiceAPI {

    struct RecordedInvocations {
        var fetchTiers: [Void] = []
        var fetchOverview: [Void] = []
        var simplifiedDueDiligenceEligibility: [KYC.Tier] = []
        var checkSimplifiedDueDiligenceEligibility: [KYC.Tier] = []
        var checkSimplifiedDueDiligenceVerification: [KYC.Tier] = []
    }

    struct StubbedResponses {
        var fetchTiers: AnyPublisher<KYC.UserTiers, KYCTierServiceError> = .empty()
        var simplifiedDueDiligenceEligibility: AnyPublisher<SimplifiedDueDiligenceResponse, Never> = .empty()
        var checkSimplifiedDueDiligenceEligibility: AnyPublisher<Bool, Never> = .empty()
        var checkSimplifiedDueDiligenceVerification: AnyPublisher<Bool, Never> = .empty()
        var fetchOverview: AnyPublisher<KYCLimitsOverview, KYCTierServiceError> = .empty()
    }

    private(set) var recordedInvocations = RecordedInvocations()
    var stubbedResponses = StubbedResponses()

    var tiers: AnyPublisher<KYC.UserTiers, KYCTierServiceError> {
        fetchTiers()
    }

    func fetchTiers() -> AnyPublisher<KYC.UserTiers, KYCTierServiceError> {
        recordedInvocations.fetchTiers.append(())
        return stubbedResponses.fetchTiers
    }

    func simplifiedDueDiligenceEligibility(for tier: KYC.Tier) -> AnyPublisher<SimplifiedDueDiligenceResponse, Never> {
        recordedInvocations.simplifiedDueDiligenceEligibility.append(tier)
        return stubbedResponses.simplifiedDueDiligenceEligibility
    }

    func checkSimplifiedDueDiligenceEligibility() -> AnyPublisher<Bool, Never> {
        checkSimplifiedDueDiligenceEligibility(for: .tier0)
    }

    func checkSimplifiedDueDiligenceEligibility(for tier: KYC.Tier) -> AnyPublisher<Bool, Never> {
        recordedInvocations.checkSimplifiedDueDiligenceEligibility.append(tier)
        return stubbedResponses.checkSimplifiedDueDiligenceEligibility
    }

    func checkSimplifiedDueDiligenceVerification(for tier: KYC.Tier, pollUntilComplete: Bool) -> AnyPublisher<Bool, Never> {
        recordedInvocations.checkSimplifiedDueDiligenceVerification.append(tier)
        return stubbedResponses.checkSimplifiedDueDiligenceVerification
    }

    func checkSimplifiedDueDiligenceVerification(pollUntilComplete: Bool) -> AnyPublisher<Bool, Never> {
        checkSimplifiedDueDiligenceVerification(for: .tier0, pollUntilComplete: pollUntilComplete)
    }

    func fetchOverview() -> AnyPublisher<KYCLimitsOverview, KYCTierServiceError> {
        recordedInvocations.fetchOverview.append(())
        return stubbedResponses.fetchOverview
    }
}
