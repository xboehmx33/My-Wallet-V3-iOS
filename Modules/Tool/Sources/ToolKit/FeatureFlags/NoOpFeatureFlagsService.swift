// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine

public class NoOpFeatureFlagsService: FeatureFlagsServiceAPI {

    public init() {}

    public func enable(_ feature: FeatureFlag) -> AnyPublisher<Void, Never> {
        .empty()
    }

    public func disable(_ feature: FeatureFlag) -> AnyPublisher<Void, Never> {
        .empty()
    }

    public func isEnabled(_ feature: FeatureFlag) -> AnyPublisher<Bool, Never> {
        .empty()
    }

    public func object<Feature>(
        for feature: FeatureFlag,
        type: Feature.Type
    ) -> AnyPublisher<Feature?, FeatureFlagError> where Feature: Decodable, Feature: Encodable {
        .empty()
    }
}
