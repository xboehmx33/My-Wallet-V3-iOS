// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import AnalyticsKit
import Combine
import ComposableArchitecture
import FeatureKYCDomain
import PlatformKit
import PlatformUIKit
import RxSwift
import ToolKit
import UIComponentsKit
import UIKit

public enum FlowResult {
    case abandoned
    case completed
}

public enum RouterError: Error {
    case emailVerificationFailed
    case kycVerificationFailed
    case kycStepFailed
}

public protocol Routing {

    /// Uses the passed-in `ViewController`to modally present another `ViewController` wrapping the entire Email Verification Flow.
    /// - Parameters:
    ///   - presenter: The `ViewController` presenting the Email Verification Flow
    ///   - emailAddress: The initial email address to verify. Note that users may change their email address in the course of the verification flow.
    ///   - flowCompletion: A closure called after the Email Verification Flow completes successully (with the email address being verified).
    func routeToEmailVerification(
        from presenter: UIViewController,
        emailAddress: String,
        flowCompletion: @escaping (FlowResult) -> Void
    )

    /// Uses the passed-in `ViewController`to modally present another `ViewController` wrapping the entire KYC Flow.
    /// - Parameters:
    ///   - presenter: The `ViewController` presenting the KYC Flow
    ///   - flowCompletion: A closure called after the KYC Flow completes successully (with the email address being verified).
    func routeToKYC(
        from presenter: UIViewController,
        requiredTier: KYC.Tier,
        flowCompletion: @escaping (FlowResult) -> Void
    )

    /// Checks if the user email is verified. If not, the Email Verification Flow will be presented.
    /// Then, the KYC status will be checked against the required tier. If the user is on a lower tier, the KYC Flow will be presented.
    /// - Parameters:
    ///   The `ViewController` presenting the Email Verification and KYC Flows
    ///   - requiredTier: the minimum KYC tier the user needs to be on to avoid presenting the KYC Flow
    func presentEmailVerificationAndKYCIfNeeded(
        from presenter: UIViewController,
        requiredTier: KYC.Tier
    ) -> AnyPublisher<FlowResult, RouterError>

    /// Checks if the user email is verified. If not, the Email Verification Flow will be presented.
    /// The `ViewController` presenting the Email Verification Flow Flow
    func presentEmailVerificationIfNeeded(
        from presenter: UIViewController
    ) -> AnyPublisher<FlowResult, RouterError>

    /// Checks the KYC status of the user against the required tier. If the user is on a lower tier, the KYC Flow will be presented.
    /// - Parameters:
    ///   The `ViewController` presenting the KYC Flow
    ///   - requiredTier: the minimum KYC tier the user needs to be on to avoid presenting the KYC Flow
    func presentKYCIfNeeded(
        from presenter: UIViewController,
        requiredTier: KYC.Tier
    ) -> AnyPublisher<FlowResult, RouterError>

    /// Presents a screen prompting the user to upgrade to Gold Tier. If the user tries to upgrade, the KYC Flow will be presented on top of the prompt.
    /// - Parameter presenter: The `ViewController` that will present the screen
    /// - Returns: A `Combine.Publisher` sending a single value before completing.
    func presentPromptToUnlockMoreTrading(
        from presenter: UIViewController
    ) -> AnyPublisher<FlowResult, Never>

    /// Checks the KYC status of the user against the required tier. If the user is on a lower tier, presents a screen prompting the user to upgrade to Gold Tier.
    /// If the user tries to upgrade, the KYC Flow will be presented on top of the prompt.
    /// - Parameters:
    ///   - from: the `ViewController` presenting the KYC Flow
    ///   - requiredTier: the minimum KYC tier the user needs to be on to avoid presenting the KYC Flow
    func presentPromptToUnlockMoreTradingIfNeeded(
        from presenter: UIViewController,
        requiredTier: KYC.Tier
    ) -> AnyPublisher<FlowResult, RouterError>

    /// Presents a limits overview screen
    func presentLimitsOverview(from presenter: UIViewController)
}

/// A class that encapsulates routing logic for the KYC flow. Use this to present the app user with any part of the KYC flow.
public class Router: Routing {

    private let legacyRouter: PlatformUIKit.KYCRouterAPI
    private let analyticsRecorder: AnalyticsEventRecorderAPI
    private let loadingViewPresenter: PlatformUIKit.LoadingViewPresenting
    private let emailVerificationService: FeatureKYCDomain.EmailVerificationServiceAPI
    private let kycService: PlatformKit.KYCTiersServiceAPI
    private let featureFlagsService: FeatureFlagsServiceAPI
    private let openMailApp: (@escaping (Bool) -> Void) -> Void
    private let openURL: (URL) -> Void

    // This should be removed once the legacy router is deleted
    private var cancellables = Set<AnyCancellable>()
    private var disposeBag = DisposeBag()

    public init(
        analyticsRecorder: AnalyticsEventRecorderAPI,
        loadingViewPresenter: PlatformUIKit.LoadingViewPresenting,
        legacyRouter: PlatformUIKit.KYCRouterAPI,
        kycService: PlatformKit.KYCTiersServiceAPI,
        featureFlagsService: FeatureFlagsServiceAPI,
        emailVerificationService: FeatureKYCDomain.EmailVerificationServiceAPI,
        openMailApp: @escaping (@escaping (Bool) -> Void) -> Void,
        openURL: @escaping (URL) -> Void
    ) {
        self.analyticsRecorder = analyticsRecorder
        self.loadingViewPresenter = loadingViewPresenter
        self.legacyRouter = legacyRouter
        self.kycService = kycService
        self.featureFlagsService = featureFlagsService
        self.emailVerificationService = emailVerificationService
        self.openMailApp = openMailApp
        self.openURL = openURL
    }

    public func routeToEmailVerification(
        from presenter: UIViewController,
        emailAddress: String,
        flowCompletion: @escaping (FlowResult) -> Void
    ) {
        presenter.present(
            EmailVerificationView(
                store: .init(
                    initialState: .init(emailAddress: emailAddress),
                    reducer: emailVerificationReducer,
                    environment: buildEmailVerificationEnvironment(
                        emailAddress: emailAddress,
                        flowCompletion: flowCompletion
                    )
                )
            )
        )
    }

    public func routeToKYC(
        from presenter: UIViewController,
        requiredTier: KYC.Tier,
        flowCompletion: @escaping (FlowResult) -> Void
    ) {
        // NOTE: you must retain the router to get the flow completion
        presentKYC(from: presenter, requiredTier: requiredTier)
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: flowCompletion)
            .store(in: &cancellables)
    }

    public func presentKYC(
        from presenter: UIViewController,
        requiredTier: KYC.Tier
    ) -> AnyPublisher<FlowResult, Never> {
        legacyRouter.start(tier: requiredTier, parentFlow: .simpleBuy)
        return Observable.merge(
            legacyRouter.kycStopped
                .map { _ in FlowResult.abandoned },
            legacyRouter.kycFinished
                .map { _ in FlowResult.completed }
        )
        // Taking one as Single ensures the Publisher completes. This fixes a bug where receiveValue on sink was called multiple times.
        .take(1)
        .asSingle()
        .asPublisher()
        .replaceError(with: FlowResult.abandoned) // should not fail, but just in case
        .eraseToAnyPublisher()
    }

    public func presentEmailVerificationAndKYCIfNeeded(
        from presenter: UIViewController,
        requiredTier: KYC.Tier
    ) -> AnyPublisher<FlowResult, RouterError> {
        // step 1: check email verification status and present email verification flow if email is unverified.
        presentEmailVerificationIfNeeded(from: presenter)
            // step 2: check KYC status and present KYC flow if user is not verified.
            .flatMap { [presentKYCIfNeeded] _ -> AnyPublisher<FlowResult, RouterError> in
                // Even if the user skips emai verification, move on to KYC
                presentKYCIfNeeded(presenter, requiredTier)
            }
            .eraseToAnyPublisher()
    }

    public func presentEmailVerificationIfNeeded(
        from presenter: UIViewController
    ) -> AnyPublisher<FlowResult, RouterError> {
        emailVerificationService
            // step 1: check email verification status.
            .checkEmailVerificationStatus()
            .mapError { _ in
                RouterError.emailVerificationFailed
            }
            .receive(on: DispatchQueue.main)
            .handleLoaderForLifecycle(loader: loadingViewPresenter)
            // step 2: present email verification screen, if needed.
            .flatMap { response -> AnyPublisher<FlowResult, RouterError> in
                switch response.status {
                case .verified:
                    // The user's email address is verified; no need to do anything. Just move on.
                    return .just(.completed)

                case .unverified:
                    // The user's email address in NOT verified; present email verification flow.
                    let publisher = PassthroughSubject<FlowResult, RouterError>()
                    self.routeToEmailVerification(from: presenter, emailAddress: response.emailAddress) { result in
                        // Because the caller of the API doesn't know if the flow got presented, we should dismiss it here
                        presenter.dismiss(animated: true) {
                            switch result {
                            case .abandoned:
                                publisher.send(.abandoned)
                            case .completed:
                                publisher.send(.completed)
                            }
                            publisher.send(completion: .finished)
                        }
                    }
                    return publisher.eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
    }

    public func presentKYCIfNeeded(
        from presenter: UIViewController,
        requiredTier: KYC.Tier
    ) -> AnyPublisher<FlowResult, RouterError> {
        guard requiredTier > .tier0 else {
            return .just(.completed)
        }

        // step 1: check KYC status.
        return kycService
            .fetchTiers()
            .receive(on: DispatchQueue.main)
            .mapError { _ in RouterError.kycStepFailed }
            .handleLoaderForLifecycle(loader: loadingViewPresenter)
            .flatMap { [routeToKYC] userTiers -> AnyPublisher<FlowResult, RouterError> in
                // step 2a: Route to KYC if the current user's tier is less than Tier 2.
                // NOTE: By guarding against Tier 1 we ensure SDD checks are performed for Tier 1 users to determine whether they are Tier 3.
                guard userTiers.latestApprovedTier > .tier1 else {
                    return Deferred { [routeToKYC] in
                        Future<FlowResult, RouterError> { futureCompletion in
                            routeToKYC(presenter, requiredTier) { result in
                                futureCompletion(.success(result))
                            }
                        }
                    }
                    .eraseToAnyPublisher()
                }

                // step 2a: if the current user's tier is greater or equal than the required tier, complete.
                guard userTiers.latestApprovedTier < requiredTier else {
                    return .just(.completed)
                }
                // step 2b: else present the kyc flow
                return Deferred {
                    Future<FlowResult, RouterError> { futureCompletion in
                        routeToKYC(presenter, requiredTier) { result in
                            futureCompletion(.success(result))
                        }
                    }
                }
                .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    public func presentPromptToUnlockMoreTradingIfNeeded(
        from presenter: UIViewController,
        requiredTier: KYC.Tier
    ) -> AnyPublisher<FlowResult, RouterError> {
        guard requiredTier > .tier0 else {
            return .just(.completed)
        }
        return kycService
            .fetchTiers()
            .receive(on: DispatchQueue.main)
            .mapError { _ in RouterError.kycStepFailed }
            .flatMap { [presentPromptToUnlockMoreTrading] userTiers -> AnyPublisher<FlowResult, RouterError> in
                guard userTiers.latestApprovedTier < requiredTier else {
                    return .just(.completed)
                }
                return presentPromptToUnlockMoreTrading(presenter)
                    .mapError()
            }
            .eraseToAnyPublisher()
    }

    public func presentPromptToUnlockMoreTrading(
        from presenter: UIViewController
    ) -> AnyPublisher<FlowResult, Never> {
        let publisher = PassthroughSubject<FlowResult, Never>()
        let view = UnlockTradingView(
            store: .init(
                initialState: UnlockTradingState(
                    viewModel: .unlockGoldTier
                ),
                reducer: unlockTradingReducer,
                environment: UnlockTradingEnvironment(
                    dismiss: {
                        presenter.dismiss(animated: true) {
                            publisher.send(.abandoned)
                            publisher.send(completion: .finished)
                        }
                    },
                    unlock: { [routeToKYC] in
                        routeToKYC(presenter, .tier2) { result in
                            presenter.dismiss(animated: true) {
                                publisher.send(result)
                            }
                        }
                    }
                )
            )
        )
        presenter.present(view)
        return publisher.eraseToAnyPublisher()
    }

    public func presentLimitsOverview(from presenter: UIViewController) {
        func internalPresentKYC(from presenter: UIViewController, requiredTier: KYC.Tier) {
            presentKYC(from: presenter, requiredTier: requiredTier)
                .receive(on: DispatchQueue.main)
                .sink(receiveValue: { _ in
                    // no-op
                })
                .store(in: &cancellables)
        }
        return featureFlagsService.isEnabled(.remote(.newLimitsUIEnabled))
            .receive(on: DispatchQueue.main)
            .handleLoaderForLifecycle(loader: loadingViewPresenter, style: .circle)
            .sink { [kycService, disposeBag, internalPresentKYC, openURL] newLimitsUIEnabled in
                guard newLimitsUIEnabled else {
                    KYCTiersViewController
                        .routeToTiers(fromViewController: presenter)
                        .disposed(by: disposeBag)
                    return
                }
                let view = TradingLimitsView(
                    store: .init(
                        initialState: TradingLimitsState(),
                        reducer: tradingLimitsReducer,
                        environment: TradingLimitsEnvironment(
                            close: {
                                presenter.dismiss(animated: true, completion: nil)
                            },
                            openURL: openURL,
                            presentKYCFlow: { requiredTier in
                                presenter.dismiss(animated: true) {
                                    internalPresentKYC(presenter, requiredTier)
                                }
                            },
                            fetchLimitsOverview: kycService.fetchOverview
                        )
                    )
                )
                presenter.present(view)
            }
            .store(in: &cancellables)
    }
}

// MARK: - Helpers

extension Router {

    func buildEmailVerificationEnvironment(
        emailAddress: String,
        flowCompletion: @escaping (FlowResult) -> Void
    ) -> EmailVerificationEnvironment {
        EmailVerificationEnvironment(
            analyticsRecorder: analyticsRecorder,
            emailVerificationService: emailVerificationService,
            flowCompletionCallback: flowCompletion,
            openMailApp: { [openMailApp] in
                .future { callback in
                    openMailApp { result in
                        callback(.success(result))
                    }
                }
            }
        )
    }
}
