// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import ToolKit

final class MockFeatureFlagsService: FeatureFlagsServiceAPI {

    struct RecordedInvocations {
        var enable: [FeatureFlag] = []
        var disable: [FeatureFlag] = []
        var isEnabled: [FeatureFlag] = []
        var object: [FeatureFlag] = []
    }

    struct StubbedResults {
        var object: AnyPublisher<Codable?, FeatureFlagError> = .empty()
    }

    private(set) var recordedInvocations = RecordedInvocations()
    var stubbedResults = StubbedResults()

    private var features: [FeatureFlag: Bool] = [:]

    func enable(_ feature: FeatureFlag) -> AnyPublisher<Void, Never> {
        features[feature] = true
        recordedInvocations.enable.append(feature)
        return .just(())
    }

    func disable(_ feature: FeatureFlag) -> AnyPublisher<Void, Never> {
        features[feature] = false
        recordedInvocations.disable.append(feature)
        return .just(())
    }

    func isEnabled(_ feature: FeatureFlag) -> AnyPublisher<Bool, Never> {
        recordedInvocations.isEnabled.append(feature)
        return .just(features[feature] ?? false)
    }

    func object<Feature: Codable>(
        for feature: FeatureFlag,
        type: Feature.Type
    ) -> AnyPublisher<Feature?, FeatureFlagError> {
        recordedInvocations.object.append(feature)
        return stubbedResults.object
            .map { $0 as? Feature }
            .eraseToAnyPublisher()
    }
}
