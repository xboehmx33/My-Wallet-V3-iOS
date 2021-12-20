//  Copyright © 2021 Blockchain Luxembourg S.A. All rights reserved.

import Combine
import DIKit
#if canImport(SharedComponentLibrary)
import SharedComponentLibrary
#else
import ComponentLibrary
#endif
import ComposableArchitecture
import ComposableArchitectureExtensions
import ComposableNavigation
import Localization
import SwiftUI
import ToolKit

struct RootViewState: Equatable, NavigationState {

    var route: RouteIntent<RootViewRoute>?

    @BindableState var tab: Tab = .home
    @BindableState var fab: FrequentAction

    @BindableState var buyAndSell: BuyAndSell = .init()
}

extension RootViewState {

    struct BuyAndSell: Equatable {

        var segment: Int = 0
    }

    struct FrequentAction: Equatable {

        var isOn: Bool = false
        var animate: Bool
        var data: Data = .init()

        struct Data: Codable, Equatable {

            var list: [Tag.Meme] = [
                blockchain.ux.user.fab.swap[],
                blockchain.ux.user.fab.send[],
                blockchain.ux.user.fab.receive[],
                blockchain.ux.user.fab.rewards[]
            ]

            var buttons: [Tag.Meme] = [
                blockchain.ux.user.fab.sell[],
                blockchain.ux.user.fab.buy[]
            ]
        }
    }
}

enum RootViewAction: Equatable, NavigationAction, BindableAction {
    case route(RouteIntent<RootViewRoute>?)
    case tab(Tab)
    case frequentAction(FrequentAction)
    case binding(BindingAction<RootViewState>)
    case onAppear
}

enum RootViewRoute: NavigationRoute {

    case account
    case QR

    @ViewBuilder func destination(in store: Store<RootViewState, RootViewAction>) -> some View {
        switch self {
        case .QR:
            QRCodeScannerView()
                .identity(blockchain.ux.user.scan.qr)
                .ignoresSafeArea()
        case .account:
            AccountView()
                .identity(blockchain.ux.user.account)
                .ignoresSafeArea(.container, edges: .bottom)
        }
    }
}

struct RootViewEnvironment: PublishedEnvironment {
    var subject: PassthroughSubject<(state: RootViewState, action: RootViewAction), Never> = .init()
    var featureFlagsService: FeatureFlagsServiceAPI = resolve()
}

let rootViewReducer = Reducer<
    RootViewState,
    RootViewAction,
    RootViewEnvironment
> { state, action, environment in
    switch action {
    case .tab(let tab):
        state.tab = tab
        return .none
    case .frequentAction(let action):
        state.fab.isOn = false
        switch action {
        case .buy:
            state.buyAndSell.segment = 0
            state.tab = .buyAndSell
        case .sell:
            state.buyAndSell.segment = 1
            state.tab = .buyAndSell
        default:
            break
        }
        return .none
    case .binding(.set(\.$fab.isOn, true)):
        state.fab.animate = false
        return .none
    case .onAppear:
        return environment.featureFlagsService.object(
            for: .remote(.fab),
            type: RootViewState.FrequentAction.Data.self
        )
        .replaceError(with: nil)
        .compactMap(\.wrapped)
        .eraseToEffect()
        .map { .binding(.set(\.$fab.data, $0)) }
    case .route, .binding:
        return .none
    }
}
.binding()
.routing()
.published()
