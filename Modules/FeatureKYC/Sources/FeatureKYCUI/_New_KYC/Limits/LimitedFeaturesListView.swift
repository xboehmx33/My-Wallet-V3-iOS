// Copyright © Blockchain Luxembourg S.A. All rights reserved.

#if canImport(SharedComponentLibrary)
import SharedComponentLibrary
#else
import ComponentLibrary
#endif
import ComposableArchitecture
import ComposableNavigation
import Localization
import PlatformKit
import SwiftUI

extension URL {

    static let customerSupport: URL = "https://support.blockchain.com/hc/en-us/articles/4410561005844"
}

enum LimitedFeaturesListRoute: NavigationRoute {

    case viewTiers

    @ViewBuilder
    func destination(in store: Store<LimitedFeaturesListState, LimitedFeaturesListAction>) -> some View {
        switch self {
        case .viewTiers:
            TiersStatusView(
                store: store.scope(
                    state: \.kycTiers,
                    action: LimitedFeaturesListAction.tiersStatusViewAction
                )
            )
        }
    }
}

struct LimitedFeaturesListState: Equatable, NavigationState {
    var route: RouteIntent<LimitedFeaturesListRoute>?
    var features: [LimitedTradeFeature]
    var kycTiers: KYC.UserTiers
}

enum LimitedFeaturesListAction: Equatable, NavigationAction {
    case route(RouteIntent<LimitedFeaturesListRoute>?)
    case viewTiersTapped
    case applyForGoldTierTapped
    case supportCenterLinkTapped
    case tiersStatusViewAction(TiersStatusViewAction)
}

struct LimitedFeaturesListEnvironment {

    let openURL: (URL) -> Void
    let presentKYCFlow: (KYC.Tier) -> Void
}

let limitedFeaturesListReducer: Reducer<
    LimitedFeaturesListState,
    LimitedFeaturesListAction,
    LimitedFeaturesListEnvironment
> = Reducer.combine(
    tiersStatusViewReducer.pullback(
        state: \LimitedFeaturesListState.kycTiers,
        action: /LimitedFeaturesListAction.tiersStatusViewAction,
        environment: {
            TiersStatusViewEnvironment(
                presentKYCFlow: $0.presentKYCFlow
            )
        }
    ),
    .init { state, action, environment in
        switch action {
        case .route(let route):
            state.route = route
            return .none

        case .viewTiersTapped:
            return .enter(into: .viewTiers, context: .none)

        case .applyForGoldTierTapped:
            return .fireAndForget {
                environment.presentKYCFlow(.tier2)
            }

        case .supportCenterLinkTapped:
            return .fireAndForget {
                environment.openURL(.customerSupport)
            }

        case .tiersStatusViewAction(let action):
            switch action {
            case .close:
                return .init(value: .dismiss())

            default:
                return .none
            }
        }
    }
)

private typealias LocalizedStrings = LocalizationConstants.KYC.LimitsOverview

extension KYC.Tier {

    fileprivate var limitsOverviewTitle: String? {
        switch self {
        case .tier0:
            return LocalizedStrings.headerTitle_tier0
        case .tier1:
            return LocalizedStrings.headerTitle_tier1
        default:
            return nil
        }
    }

    fileprivate var limitsOverviewMessage: String {
        switch self {
        case .tier0:
            return LocalizedStrings.headerMessage_tier0
        case .tier1:
            return LocalizedStrings.headerMessage_tier1
        default:
            return LocalizedStrings.headerMessage_tier2
        }
    }
}

struct LimitedFeaturesListView: View {

    let store: Store<LimitedFeaturesListState, LimitedFeaturesListAction>

    var body: some View {
        WithViewStore(store) { viewStore in
            let latestApprovedTier = viewStore.kycTiers.latestApprovedTier
            let hasPendingState = viewStore.kycTiers.tiers.contains(
                where: { $0.state == .pending }
            )
            let tierForHeader = hasPendingState ? .tier0 : latestApprovedTier
            ScrollView {
                VStack(alignment: .leading, spacing: .zero) {
                    LimitedFeaturesListHeader(kycTier: tierForHeader) {
                        if tierForHeader.isZero {
                            viewStore.send(.viewTiersTapped)
                        } else {
                            viewStore.send(.applyForGoldTierTapped)
                        }
                    }
                    .listRowInsets(.zero)
                    .padding(.bottom, Spacing.padding3)

                    Section(
                        header: SectionHeader(
                            title: LocalizedStrings.featureListHeader
                        ),
                        footer: LimitedFeaturesListFooter()
                            .onTapGesture {
                                viewStore.send(.supportCenterLinkTapped)
                            }
                    ) {
                        if latestApprovedTier > .tier0 {
                            TierTradeLimitCell(tier: latestApprovedTier)
                            PrimaryDivider()
                        }
                        ForEach(viewStore.features) { feature in
                            LimitedTradeFeatureCell(feature: feature)
                            PrimaryDivider()
                        }
                    }
                    .textCase(nil) // to avoid default transformation to uppercase
                    .listRowInsets(.zero)
                }
            }
            .navigationRoute(in: store)
        }
    }
}

struct LimitedFeaturesListHeader: View {

    let kycTier: KYC.Tier
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.padding3) {
            VStack(alignment: .leading, spacing: Spacing.textSpacing) {
                if let title = kycTier.limitsOverviewTitle {
                    Text(title)
                        .typography(.body2)
                }
                Text(kycTier.limitsOverviewMessage)
                    .typography(.paragraph1)
            }
            if kycTier.isZero {
                ComponentLibrary.PrimaryButton(
                    title: LocalizedStrings.headerCTA_tier0,
                    action: action
                )
            } else if kycTier.isSiver {
                ComponentLibrary.PrimaryButton(
                    title: LocalizedStrings.headerCTA_tier1,
                    action: action
                )
            }
        }
        .padding(.horizontal, Spacing.padding3)
    }
}

struct LimitedFeaturesListFooter: View {

    var body: some View {
        let mainText = LocalizedStrings.footerTemplate
        let supportCenterText = Text(LocalizedStrings.supportCenterLink)
            .typography(.caption1)
            .foregroundColor(.semantic.primary)
        let components: [Text] = mainText
            .components(separatedBy: "|SUPPORT_CENTER|")
            .map { substring in
                Text(substring)
                    .typography(.caption1)
                    .foregroundColor(.semantic.body)
            }
        let joined = components[0] + supportCenterText + components[1]
        return joined
            .padding(Spacing.padding3)
    }
}

struct LimitedFeaturesListView_Previews: PreviewProvider {

    static var previews: some View {
        LimitedFeaturesListView(
            store: .init(
                initialState: LimitedFeaturesListState(
                    features: [],
                    kycTiers: .init(tiers: [])
                ),
                reducer: limitedFeaturesListReducer,
                environment: LimitedFeaturesListEnvironment(
                    openURL: { _ in },
                    presentKYCFlow: { _ in }
                )
            )
        )
    }
}
