// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import TestKit
import XCTest

@testable import FeatureTransactionDomainMock
@testable import FeatureTransactionUI
@testable import FeatureTransactionUIMock
@testable import PlatformKitMock
@testable import PlatformUIKitMock
@testable import ToolKitMock

// Temporary disable tests
// final class TransactionsRouterTests: XCTestCase {
//
//    private var router: TransactionsRouter!
//    private var mockBuyFlowBuilder: MockBuyFlowBuilder!
//    private var mockLegacyBuyFlowRouter: MockLegacyBuyFlowRouter!
//    private var mockFeatureFlagsService: MockFeatureFlagsService!
//    private var mockEligibilityService: MockEligibilityService!
//    private var sellFlowBuilder: SellFlowBuildable!
//    private var signFlowBuilder: SignFlowBuildable!
//    private var sendFlowBuilder: SendRootBuildable!
//    private var interestFlowBuilder: InterestTransactionBuilder!
//    private var withdrawFlowBuilder: WithdrawRootBuildable!
//    private var depositFlowBuilder: DepositRootBuildable!
//    private var receiveCooridnator: ReceiveCoordinator!
//    private var tabSwapping: TabSwappingMock!
//
//    override func setUpWithError() throws {
//        try super.setUpWithError()
//        mockFeatureFlagsService = MockFeatureFlagsService()
//        mockLegacyBuyFlowRouter = MockLegacyBuyFlowRouter()
//        mockBuyFlowBuilder = MockBuyFlowBuilder()
//        mockEligibilityService = MockEligibilityService()
//        tabSwapping = TabSwappingMock()
//        router = TransactionsRouter(
//            featureFlagsService: mockFeatureFlagsService,
//            pendingOrdersService: MockPendingOrderDetailsService(),
//            kycRouter: MockTransactionsKYCRouter(),
//            alertViewPresenter: MockAlertViewPresenter(),
//            topMostViewControllerProvider: MockTopMostViewControllerProvider(),
//            loadingViewPresenter: MockLoadingViewPresenter(),
//            legacyBuyRouter: mockLegacyBuyFlowRouter,
//            buyFlowBuilder: mockBuyFlowBuilder,
//            sellFlowBuilder: sellFlowBuilder,
//            signFlowBuilder: signFlowBuilder,
//            sendFlowBuilder: sendFlowBuilder,
//            interestFlowBuilder: interestFlowBuilder,
//            withdrawFlowBuilder: withdrawFlowBuilder,
//            depositFlowBuilder: depositFlowBuilder,
//            eligibilityService: mockEligibilityService,
//            receiveCooridnator: receiveCooridnator,
//            tabSwapping: tabSwapping
//        )
//    }
//
//    override func tearDownWithError() throws {
//        try super.tearDownWithError()
//        router = nil
//        mockFeatureFlagsService = nil
//        mockLegacyBuyFlowRouter = nil
//    }
//
//    func test_routesTo_legacyBuyFlow_forCryptoAccount_featueFlagOff() throws {
//        XCTAssertPublisherCompletion(mockFeatureFlagsService.disable(.remote(.useTransactionsFlowToBuyCrypto)))
//        let mockViewController = MockViewController()
//        let cryptoAccount = ReceivePlaceholderCryptoAccount(
//            asset: .coin(.bitcoin)
//        )
//        let publisher = router.presentTransactionFlow(to: .buy(cryptoAccount), from: mockViewController)
//        XCTAssertPublisherCompletion(publisher)
//        let recordedInvocations = mockLegacyBuyFlowRouter.recordedInvocations
//        XCTAssertEqual(recordedInvocations.presentBuyScreen, 1)
//    }
//
//    func test_routesTo_legacyBuyFlow_nilAccount_featueFlagOff() throws {
//        XCTAssertPublisherCompletion(mockFeatureFlagsService.disable(.remote(.useTransactionsFlowToBuyCrypto)))
//        let mockViewController = MockViewController()
//        let publisher = router.presentTransactionFlow(to: .buy(nil), from: mockViewController)
//        XCTAssertPublisherCompletion(publisher)
//        let recordedInvocations = mockLegacyBuyFlowRouter.recordedInvocations
//        XCTAssertEqual(recordedInvocations.presentBuyFlowWithTargetCurrencySelectionIfNecessary, 1)
//    }
//
//    func test_routesTo_legacyBuyFlow_featueFlagOn_nilAccount() throws {
//        XCTAssertPublisherCompletion(mockFeatureFlagsService.enable(.remote(.useTransactionsFlowToBuyCrypto)))
//        let mockViewController = MockViewController()
//        let publisher = router.presentTransactionFlow(to: .buy(nil), from: mockViewController)
//        XCTAssertPublisherCompletion(publisher)
//        let mockRouter = mockBuyFlowBuilder.builtRouters.first
//        let buyStartRequests = mockRouter?.recordedInvocations.start
//        XCTAssertEqual(buyStartRequests?.count, 1)
//        XCTAssertNil(buyStartRequests?.first?.cryptoAccount)
//    }
//
//    func test_routesTo_legacyBuyFlow_featueFlagOn_nonNilAccount() throws {
//        XCTAssertPublisherCompletion(mockFeatureFlagsService.enable(.remote(.useTransactionsFlowToBuyCrypto)))
//        let mockViewController = MockViewController()
//        let cryptoAccount = ReceivePlaceholderCryptoAccount(
//            asset: .coin(.bitcoin)
//        )
//        let publisher = router.presentTransactionFlow(to: .buy(cryptoAccount), from: mockViewController)
//        XCTAssertPublisherCompletion(publisher)
//        let mockRouter = mockBuyFlowBuilder.builtRouters.first
//        let buyStartRequests = mockRouter?.recordedInvocations.start
//        XCTAssertEqual(buyStartRequests?.count, 1)
//        XCTAssertEqual(buyStartRequests?.first?.cryptoAccount?.asset, .coin(.bitcoin))
//    }
// }
