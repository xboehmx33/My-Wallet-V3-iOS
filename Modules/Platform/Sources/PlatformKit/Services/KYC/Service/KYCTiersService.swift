// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import AnalyticsKit
import Combine
import DIKit
import NabuNetworkError
import NetworkError
import RxSwift
import ToolKit

public enum KYCTierServiceError: Error, Equatable {
    case networkError(NetworkError)
    case other(Error)

    public static func == (lhs: KYCTierServiceError, rhs: KYCTierServiceError) -> Bool {
        String(describing: lhs) == String(describing: rhs)
    }
}

public protocol KYCVerificationServiceAPI: AnyObject {

    /// Returnes whether or not the user is Tier 2 approved.
    var isKYCVerified: AnyPublisher<Bool, Never> { get }

    // Returns whether or not the user can make purchases
    var canPurchaseCrypto: AnyPublisher<Bool, Never> { get }
}

public protocol KYCTiersServiceAPI: KYCVerificationServiceAPI {

    /// Returns the cached tiers. Fetches them if they are not already cached
    var tiers: AnyPublisher<KYC.UserTiers, KYCTierServiceError> { get }

    /// Fetches the tiers from remote
    func fetchTiers() -> AnyPublisher<KYC.UserTiers, KYCTierServiceError>

    /// Fetches the Simplified Due Diligence Eligibility Status returning the whole response
    func simplifiedDueDiligenceEligibility(
        for tier: KYC.Tier
    ) -> AnyPublisher<SimplifiedDueDiligenceResponse, Never>

    /// Fetches Simplified Due Diligence Eligibility Status
    func checkSimplifiedDueDiligenceEligibility() -> AnyPublisher<Bool, Never>

    /// Fetches Simplified Due Diligence Eligibility Status
    func checkSimplifiedDueDiligenceEligibility(
        for tier: KYC.Tier
    ) -> AnyPublisher<Bool, Never>

    /// Fetches the Simplified Due Diligence Verification Status. It pools the API until a valid result is available. If the check fails, it returns `false`.
    func checkSimplifiedDueDiligenceVerification(
        for tier: KYC.Tier,
        pollUntilComplete: Bool
    ) -> AnyPublisher<Bool, Never>

    /// Checks if the current user is SDD Verified
    func checkSimplifiedDueDiligenceVerification(
        pollUntilComplete: Bool
    ) -> AnyPublisher<Bool, Never>

    /// Fetches the KYC overview (features and limits) for the logged-in user
    func fetchOverview() -> AnyPublisher<KYCLimitsOverview, KYCTierServiceError>
}

extension KYCTiersServiceAPI {

    /// Returnes whether or not the user is Tier 2 approved.
    public var isKYCVerified: AnyPublisher<Bool, Never> {
        fetchTiers()
            .map(\.isTier2Approved)
            .replaceError(with: false)
            .eraseToAnyPublisher()
    }

    /// Returns whether or not the user can make purchases
    public var canPurchaseCrypto: AnyPublisher<Bool, Never> {
        fetchTiers()
            .zip(
                checkSimplifiedDueDiligenceVerification(pollUntilComplete: false)
                    .setFailureType(to: KYCTierServiceError.self)
            )
            .map { userTiers, isSDDVerified -> Bool in
                // users can make purchases if they are at least Tier 2 approved or Tier 3 (Tier 1 and SDD Verified)
                userTiers.canPurchaseCrypto(isSDDVerified: isSDDVerified)
            }
            .replaceError(with: false)
            .eraseToAnyPublisher()
    }
}

final class KYCTiersService: KYCTiersServiceAPI {

    // MARK: - Types

    private struct Key: Hashable {}

    // MARK: - Exposed Properties

    var tiers: AnyPublisher<KYC.UserTiers, KYCTierServiceError> {
        cachedTiers.get(key: Key())
    }

    // MARK: - Private Properties

    private let client: KYCClientAPI
    private let featureFlagsService: FeatureFlagsServiceAPI
    private let analyticsRecorder: AnalyticsEventRecorderAPI
    private let cachedTiers: CachedValueNew<
        Key,
        KYC.UserTiers,
        KYCTierServiceError
    >
    private let scheduler = SerialDispatchQueueScheduler(qos: .default)

    // MARK: - Setup

    init(
        client: KYCClientAPI = resolve(),
        featureFlagsService: FeatureFlagsServiceAPI = resolve(),
        analyticsRecorder: AnalyticsEventRecorderAPI = resolve()
    ) {
        self.client = client
        self.featureFlagsService = featureFlagsService
        self.analyticsRecorder = analyticsRecorder

        let cache: AnyCache<Key, KYC.UserTiers> = InMemoryCache(
            configuration: .onLoginLogout(),
            refreshControl: PerpetualCacheRefreshControl()
        ).eraseToAnyCache()
        cachedTiers = CachedValueNew(
            cache: cache,
            fetch: { _ in
                client
                    .tiers()
                    .mapErrorToKYCServiceError()
            }
        )
    }

    func fetchTiers() -> AnyPublisher<KYC.UserTiers, KYCTierServiceError> {
        cachedTiers.get(key: Key(), forceFetch: true)
    }

    func simplifiedDueDiligenceEligibility(for tier: KYC.Tier) -> AnyPublisher<SimplifiedDueDiligenceResponse, Never> {
        guard tier != .tier2 else {
            // Tier2 (Gold) verified users should be treated as SDD eligible
            return .just(SimplifiedDueDiligenceResponse(eligible: true, tier: tier.rawValue))
        }
        return featureFlagsService.isEnabled(.remote(.sddEnabled))
            .flatMap { [client] sddEnabled -> AnyPublisher<SimplifiedDueDiligenceResponse, Never> in
                guard sddEnabled else {
                    return .just(SimplifiedDueDiligenceResponse(eligible: false, tier: KYC.Tier.tier0.rawValue))
                }
                return client.checkSimplifiedDueDiligenceEligibility()
                    .replaceError(with: SimplifiedDueDiligenceResponse(eligible: false, tier: tier.rawValue))
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    func checkSimplifiedDueDiligenceEligibility() -> AnyPublisher<Bool, Never> {
        featureFlagsService.isEnabled(.remote(.sddEnabled))
            .flatMap { [fetchTiers, simplifiedDueDiligenceEligibility] sddEnabled -> AnyPublisher<Bool, Never> in
                guard sddEnabled else {
                    return .just(false)
                }
                return fetchTiers()
                    .flatMap { userTiers -> AnyPublisher<Bool, KYCTierServiceError> in
                        simplifiedDueDiligenceEligibility(userTiers.latestApprovedTier)
                            .map(\.eligible)
                            .setFailureType(to: KYCTierServiceError.self)
                            .eraseToAnyPublisher()
                    }
                    .replaceError(with: false)
                    .eraseToAnyPublisher()
            }
            .handleEvents(receiveOutput: { [analyticsRecorder] isSDDEligible in
                if isSDDEligible {
                    analyticsRecorder.record(event: SDDAnalytics.userIsSddEligible)
                }
            })
            .eraseToAnyPublisher()
    }

    func checkSimplifiedDueDiligenceEligibility(for tier: KYC.Tier) -> AnyPublisher<Bool, Never> {
        simplifiedDueDiligenceEligibility(for: tier)
            .map(\.eligible)
            .eraseToAnyPublisher()
    }

    func checkSimplifiedDueDiligenceVerification(
        for tier: KYC.Tier,
        pollUntilComplete: Bool
    ) -> AnyPublisher<Bool, Never> {
        guard tier != .tier2 else {
            // Tier 2 (Gold) verified users should be treated as SDD verified
            return .just(true)
        }

        return featureFlagsService.isEnabled(.remote(.sddEnabled))
            .flatMap { [client] sddEnabled -> AnyPublisher<Bool, Never> in
                guard sddEnabled else {
                    return .just(false)
                }
                return client
                    .checkSimplifiedDueDiligenceVerification()
                    .startPolling(until: { response in
                        response.taskComplete || !pollUntilComplete
                    })
                    .replaceError(with: SimplifiedDueDiligenceVerificationResponse(verified: false, taskComplete: true))
                    .map(\.verified)
                    .eraseToAnyPublisher()
            }
            .handleEvents(receiveOutput: { [analyticsRecorder] isSDDEligible in
                if isSDDEligible {
                    analyticsRecorder.record(event: SDDAnalytics.userIsSddEligible)
                }
            })
            .eraseToAnyPublisher()
    }

    func checkSimplifiedDueDiligenceVerification(pollUntilComplete: Bool) -> AnyPublisher<Bool, Never> {
        let sddVerificationCheck = checkSimplifiedDueDiligenceVerification(for:pollUntilComplete:)
        return featureFlagsService.isEnabled(.remote(.sddEnabled))
            .flatMap { [fetchTiers, sddVerificationCheck] sddEnabled -> AnyPublisher<Bool, Never> in
                guard sddEnabled else {
                    return .just(false)
                }
                return fetchTiers()
                    .flatMap { userTiers -> AnyPublisher<Bool, KYCTierServiceError> in
                        sddVerificationCheck(userTiers.latestApprovedTier, pollUntilComplete)
                            .setFailureType(to: KYCTierServiceError.self)
                            .eraseToAnyPublisher()
                    }
                    .replaceError(with: false)
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    func fetchOverview() -> AnyPublisher<KYCLimitsOverview, KYCTierServiceError> {
        fetchTiers()
            .zip(
                client
                    .fetchLimitsOverview()
                    .mapErrorToKYCServiceError()
            )
            .map { tiers, rawOverview -> KYCLimitsOverview in
                KYCLimitsOverview(tiers: tiers, features: rawOverview.limits)
            }
            .eraseToAnyPublisher()
    }
}

/// Temporary legacy SDD analytics events definition. To be removed after dropping Firebase analytics.
enum SDDAnalytics: AnalyticsEvent {

    case userIsSddEligible

    var type: AnalyticsEventType {
        .firebase
    }

    var name: String {
        "user_is_sdd_eligible"
    }

    var params: [String: Any]? {
        nil
    }
}

extension Publisher where Failure == NabuNetworkError {

    func mapErrorToKYCServiceError() -> AnyPublisher<Output, KYCTierServiceError> {
        mapError { nabuError -> KYCTierServiceError in
            switch nabuError {
            case .communicatorError(let networkError):
                return .networkError(networkError)
            case .nabuError:
                return .other(nabuError)
            }
        }
        .eraseToAnyPublisher()
    }
}
