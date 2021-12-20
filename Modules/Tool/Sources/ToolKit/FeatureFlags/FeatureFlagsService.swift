// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import DIKit

public enum FeatureFlag: Hashable {
    case local(InternalFeature)
    case remote(AppFeature)

    /// Enables the feature for alpha release overriding any internal or external config.
    var isAlphaReady: Bool {
        switch self {
        case .local(let feature):
            return feature.isAlphaReady
        case .remote(let feature):
            return feature.isAlphaReady
        }
    }
}

public enum BuildFlag {
    public static var isAlpha: Bool = false
    public static var isInternal: Bool = false
}

public enum FeatureFlagError: Error {
    case decodingError(Error)
}

/// Types adopting the `FeatureConfiguratorAPI` should provide a way to initialize and configure a
/// remote based feature flag system
public protocol FeatureConfiguratorAPI: FeatureInitializer, FeatureConfiguring {}

public enum FeatureConfigurationError: Error {
    case missingKeyRawValue
    case missingValue
    case decodingError
}

public protocol FeatureInitializer: AnyObject {
    func initialize()
}

/// Any feature remote configuration protocol
public protocol FeatureConfiguring: AnyObject {
    func configuration(for feature: AppFeature) -> AppFeatureConfiguration
    func configuration<Feature: Decodable>(for feature: AppFeature) -> Result<Feature, FeatureConfigurationError>
}

/// This is the interface all modules should use for feature flags.
/// It replaces `InternalFeatureFlagServiceAPI` and `FeatureFetching` by wrapping them under a unified set of APIs.
/// This is to avoid having to change business logic when moving from internally-driven to externally-driven feature flags and may be extended to allow the use of either at the same time.
public protocol FeatureFlagsServiceAPI {

    func enable(_ feature: FeatureFlag) -> AnyPublisher<Void, Never>
    func disable(_ feature: FeatureFlag) -> AnyPublisher<Void, Never>
    func isEnabled(_ feature: FeatureFlag) -> AnyPublisher<Bool, Never>
    func object<Feature: Codable>(
        for feature: FeatureFlag,
        type: Feature.Type
    ) -> AnyPublisher<Feature?, FeatureFlagError>
}

extension FeatureFlagsServiceAPI {

    public func object<Feature: Codable>(for feature: FeatureFlag) -> AnyPublisher<Feature?, FeatureFlagError> {
        object(for: feature, type: Feature.self)
    }
}

public protocol FeatureFetching: AnyObject {
    func fetch<Feature: Decodable>(for key: AppFeature) -> AnyPublisher<Feature, FeatureFlagError>
}

class FeatureFlagsService: FeatureFlagsServiceAPI {

    private let localFeatureFlagsService: InternalFeatureFlagServiceAPI
    private let remoteFeatureFlagsService: FeatureFetching
    private let appFeatureConfigurator: FeatureConfiguratorAPI

    init(
        localFeatureFlagsService: InternalFeatureFlagServiceAPI = resolve(),
        remoteFeatureFlagsService: FeatureFetching = resolve(),
        appFeatureConfigurator: FeatureConfiguratorAPI = resolve()
    ) {
        self.localFeatureFlagsService = localFeatureFlagsService
        self.remoteFeatureFlagsService = remoteFeatureFlagsService
        self.appFeatureConfigurator = appFeatureConfigurator
    }

    func enable(_ feature: FeatureFlag) -> AnyPublisher<Void, Never> {
        switch feature {
        case .local(let featureFlag):
            localFeatureFlagsService.enable(featureFlag)
            return .just(())

        case .remote:
            impossible("To enable a remote feature flag you have to visit your provider's website.")
        }
    }

    func disable(_ feature: FeatureFlag) -> AnyPublisher<Void, Never> {
        switch feature {
        case .local(let featureFlag):
            localFeatureFlagsService.disable(featureFlag)
            return .just(())

        case .remote:
            impossible("To enable a remote feature flag you have to visit your provider's website.")
        }
    }

    func isEnabled(_ feature: FeatureFlag) -> AnyPublisher<Bool, Never> {
        if BuildFlag.isAlpha, feature.isAlphaReady {
            return .just(true)
        }
        switch feature {
        case .local(let featureFlag):
            return .just(localFeatureFlagsService.isEnabled(featureFlag))

        case .remote(let featureFlag):
            return remoteFeatureFlagsService.fetch(for: featureFlag)
                .replaceError(with: false)
                .eraseToAnyPublisher()
        }
    }

    func object<Feature: Codable>(
        for feature: FeatureFlag,
        type: Feature.Type
    ) -> AnyPublisher<Feature?, FeatureFlagError> {
        switch feature {
        case .local:
            unimplemented("Objects are not yet supported for local feature flags")

        case .remote(let featureFlag):
            return remoteFeatureFlagsService.fetch(for: featureFlag)
                .mapError { error in
                    FeatureFlagError.decodingError(error)
                }
                .eraseToAnyPublisher()
        }
    }
}
