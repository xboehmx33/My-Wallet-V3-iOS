// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import ComposableArchitecture
import ComposableNavigation
@testable import FeatureKYCUI
import PlatformKit
import TestKit
import XCTest

final class TradingLimitsViewTests: XCTestCase {

    struct RecordedInvocations {
        var close: [Void] = []
        var openURL: [URL] = []
        var presentKYC: [KYC.Tier] = []
    }

    private var testStore: TestStore<
        TradingLimitsState,
        TradingLimitsState,
        TradingLimitsAction,
        TradingLimitsAction,
        TradingLimitsEnvironment
    >!
    private let testScheduler: TestSchedulerOf<DispatchQueue> = DispatchQueue.test

    private var recordedInvocations = RecordedInvocations()
    private var stubOverview = KYCLimitsOverview(
        tiers: .init(
            tiers: [
                .init(tier: .tier1, state: .verified),
                .init(tier: .tier2, state: .pending)
            ]
        ),
        features: [
            LimitedTradeFeature(id: .send, enabled: false, limit: nil)
        ]
    )

    override func setUpWithError() throws {
        try super.setUpWithError()
        resetStore()
    }

    override func tearDownWithError() throws {
        testStore = nil
        try super.tearDownWithError()
    }

    func test_initial_load_success() throws {
        testStore.assert(
            .send(.fetchLimits) {
                $0.loading = true
            },
            .do { [testScheduler] in
                testScheduler.advance()
            },
            .receive(.didFetchLimits(.success(stubOverview))) { [stubOverview] in
                $0.loading = false
                $0.userTiers = stubOverview.tiers
                $0.featuresList = LimitedFeaturesListState(
                    features: stubOverview.features,
                    kycTiers: stubOverview.tiers
                )
            }
        )
    }

    func test_initial_load_failure() throws {
        resetStore(failCalls: true)
        testStore.assert(
            .send(.fetchLimits) {
                $0.loading = true
            },
            .do { [testScheduler] in
                testScheduler.advance(by: .seconds(2))
            },
            .receive(.didFetchLimits(.failure(KYCTierServiceError.other(MockError.unknown)))) {
                $0.loading = false
                $0.featuresList = LimitedFeaturesListState(
                    features: [],
                    kycTiers: .init(tiers: [])
                )
            }
        )
    }

    func test_initial_load_emptyResult() throws {
        resetOverviewForEmptyState()
        testStore.assert(
            .send(.fetchLimits) {
                $0.loading = true
            },
            .do { [testScheduler] in
                testScheduler.advance(by: .seconds(2))
            },
            .receive(.didFetchLimits(.success(stubOverview))) { [stubOverview] in
                $0.loading = false
                $0.userTiers = stubOverview.tiers
                $0.featuresList = LimitedFeaturesListState(
                    features: stubOverview.features,
                    kycTiers: stubOverview.tiers
                )
            }
        )
    }

    func test_close() throws {
        testStore.assert(
            .send(.close),
            .do { [unowned self] in
                XCTAssertEqual(self.recordedInvocations.close.count, 1)
            }
        )
    }

    func test_present_support_center() throws {
        testStore.assert(
            .send(.listAction(.supportCenterLinkTapped)),
            .do { [unowned self] in
                XCTAssertEqual(self.recordedInvocations.openURL, [.customerSupport])
            }
        )
    }

    func test_apply_for_gold() throws {
        testStore.assert(
            .send(.listAction(.applyForGoldTierTapped)),
            .do { [unowned self] in
                XCTAssertEqual(self.recordedInvocations.presentKYC, [.tier2])
            }
        )
    }

    func test_view_tiers() throws {
        testStore.assert(
            .send(.listAction(.viewTiersTapped)),
            .receive(.listAction(.enter(into: .viewTiers, context: .none))) {
                $0.featuresList.route = .init(route: .viewTiers, action: .enterInto(.none))
            }
        )
    }

    func test_view_tiers_close_modal() throws {
        testStore.assert(
            .send(.listAction(.tiersStatusViewAction(.close))),
            .receive(.listAction(.dismiss())) {
                $0.featuresList.route = nil
            }
        )
    }

    func test_presentKYC_tier1() throws {
        XCTAssertEqual(stubOverview.tiers.latestApprovedTier, .tier1)
        testStore.assert(
            .send(.didFetchLimits(.success(stubOverview))) { [stubOverview] in
                $0.loading = false
                $0.userTiers = stubOverview.tiers
                $0.featuresList = LimitedFeaturesListState(
                    features: stubOverview.features,
                    kycTiers: stubOverview.tiers
                )
            },
            .send(.listAction(.tiersStatusViewAction(.tierTapped(.tier1)))),
            .do { [unowned self] in
                XCTAssertEqual(self.recordedInvocations.presentKYC, [])
            }
        )
    }

    func test_presentKYC_tier2() throws {
        XCTAssertEqual(stubOverview.tiers.latestApprovedTier, .tier1)
        testStore.assert(
            .send(.didFetchLimits(.success(stubOverview))) { [stubOverview] in
                $0.loading = false
                $0.userTiers = stubOverview.tiers
                $0.featuresList = LimitedFeaturesListState(
                    features: stubOverview.features,
                    kycTiers: stubOverview.tiers
                )
            },
            .send(.listAction(.tiersStatusViewAction(.tierTapped(.tier2)))),
            .do { [unowned self] in
                XCTAssertEqual(self.recordedInvocations.presentKYC, [.tier2])
            }
        )
    }

    // MARK: - Helpers

    func resetStore(failCalls: Bool = false) {
        testStore = .init(
            initialState: TradingLimitsState(
                loading: false,
                userTiers: nil,
                featuresList: LimitedFeaturesListState(
                    features: [],
                    kycTiers: .init(tiers: [])
                )
            ),
            reducer: tradingLimitsReducer,
            environment: TradingLimitsEnvironment(
                close: { [weak self] in
                    self?.recordedInvocations.close.append(())
                },
                openURL: { [weak self] url in
                    self?.recordedInvocations.openURL.append(url)
                },
                presentKYCFlow: { tier in
                    self.recordedInvocations.presentKYC.append(tier)
                },
                fetchLimitsOverview: { [unowned self] in
                    guard failCalls else {
                        return .just(self.stubOverview)
                    }
                    return .failure(KYCTierServiceError.other(MockError.unknown))
                },
                mainQueue: testScheduler.eraseToAnyScheduler()
            )
        )
    }

    func resetOverviewForEmptyState() {
        stubOverview = KYCLimitsOverview(
            tiers: .init(
                tiers: [
                    .init(tier: .tier1, state: .verified),
                    .init(tier: .tier2, state: .pending)
                ]
            ),
            features: []
        )
    }
}
