// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import ComposableArchitecture
import FeatureAuthenticationUI
import FeatureTourUI
import Localization
import SwiftUI
import ToolKit
import UIComponentsKit

public struct TourViewAdapter: View {

    private let store: Store<WelcomeState, WelcomeAction>
    private let featureFlagService: FeatureFlagsServiceAPI

    @State var newTourEnabled: Bool?

    public init(store: Store<WelcomeState, WelcomeAction>, featureFlagService: FeatureFlagsServiceAPI) {
        self.store = store
        self.featureFlagService = featureFlagService
    }

    public var body: some View {
        Group {
            switch newTourEnabled {
            case nil:
                LoadingStateView(title: "")
            case true?:
                WithViewStore(store) { viewStore in
                    TourView(
                        environment: TourEnvironment(
                            createAccountAction: { viewStore.send(.navigate(to: .createWallet)) },
                            restoreAction: { viewStore.send(.enter(into: .restoreWallet)) },
                            logInAction: { viewStore.send(.enter(into: .emailLogin)) }
                        )
                    )
                }
                .navigationRoute(in: store)
            case false?:
                WelcomeView(store: store)
                    .primaryNavigation()
                    .navigationBarHidden(true)
            }
        }
        .onReceive(featureFlagService.isEnabled(.remote(.newOnboardingTour))) { isEnabled in
            newTourEnabled = isEnabled
        }
    }
}
