// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import ComposableArchitecture
import Localization
import MoneyKit
import SwiftUI

struct LivePricesView: View {

    let store: Store<TourState, TourAction>
    let list: LivePricesList

    var body: some View {
        WithViewStore(store) { viewStore in
            VStack {
                LivePricesHeader(
                    offset: viewStore.binding(
                        get: \.scrollOffset,
                        send: TourAction.none
                    )
                )
                list.mask(
                    LinearGradient(
                        gradient: Gradient(
                            colors: [
                                Color.black,
                                Color.black,
                                Color.black.opacity(0.2),
                                Color.black.opacity(0.03)
                            ]
                        ),
                        startPoint: UnitPoint(x: 0.5, y: viewStore.priceListMaskStartYPoint),
                        endPoint: .bottom
                    )
                )
                .onPreferenceChange(OffsetKey.self) {
                    viewStore.send(.priceListDidScroll(offset: $0))
                }
            }
            .padding(.top)
        }
    }
}

struct OffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct PriceListView_Previews: PreviewProvider {

    static let items = [
        Price(currency: .coin(.bitcoin), value: .loaded(next: "$55,343.76"), deltaPercentage: .loaded(next: 7.88)),
        Price(currency: .coin(.ethereum), value: .loaded(next: "$3,585.69"), deltaPercentage: .loaded(next: 1.82)),
        Price(currency: .coin(.bitcoinCash), value: .loaded(next: "$618.05"), deltaPercentage: .loaded(next: -3.46)),
        Price(currency: .coin(.stellar), value: .loaded(next: "$0.36"), deltaPercentage: .loaded(next: 12.50))
    ]

    static var tourState: TourState {
        var tourState = TourState()
        tourState.items = IdentifiedArray(uniqueElements: items)
        return tourState
    }

    static var reducer: Reducer<TourState, TourAction, TourEnvironment> = Reducer { _, _, _ in
        .none
    }

    static var store = Store(
        initialState: tourState,
        reducer: reducer,
        environment: TourEnvironment(createAccountAction: {}, restoreAction: {}, logInAction: {})
    )

    static var previews: some View {
        LivePricesView(
            store: store,
            list: LivePricesList(store: store)
        )
    }
}
