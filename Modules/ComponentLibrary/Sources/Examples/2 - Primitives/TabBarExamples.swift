// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import ComponentLibrary
import SwiftUI

struct TabBarExamplesView: View {
    @State var wallet: AnyHashable = WalletPreviewContainer.Tab.home
    @State var exchange: AnyHashable = ExchangePreviewContainer.Tab.home

    var body: some View {
        NavigationLinkProviderView(
            data: [
                "Examples": [
                    NavigationLinkProvider(
                        view: WalletPreviewContainer(
                            activeTabIdentifier: wallet,
                            fabIsActive: false
                        ),
                        title: "Wallet"
                    ),
                    NavigationLinkProvider(
                        view: ExchangePreviewContainer(
                            activeTabIdentifier: exchange
                        ),
                        title: "Exchange"
                    )
                ]
            ]
        )
    }

    struct WalletPreviewContainer: View {
        enum Tab: Hashable {
            case home
            case prices
            case rewards
            case activity
        }

        @State var activeTabIdentifier: AnyHashable
        @State var fabIsActive: Bool

        var body: some View {
            TabBar(
                activeTabIdentifier: $activeTabIdentifier,
                highlightBarVisible: true
            ) {
                Text("Home")
                    .tabBarItem(
                        .tab(
                            identifier: Tab.home,
                            icon: .home,
                            title: "Home"
                        )
                    )

                Text("Prices")
                    .tabBarItem(
                        .tab(
                            identifier: Tab.prices,
                            icon: .lineChartUp,
                            title: "Prices"
                        )
                    )

                Text("Foo")
                    .tabBarItem(
                        .fab(
                            identifier: "floatingActionButtonIdentifier",
                            isActive: $fabIsActive,
                            isPulsing: true
                        )
                    )

                Text("Rewards")
                    .tabBarItem(
                        .tab(
                            identifier: Tab.rewards,
                            icon: .interestCircle,
                            title: "Rewards"
                        )
                    )

                Text("Activity")
                    .tabBarItem(
                        .tab(
                            identifier: Tab.activity,
                            icon: .pending,
                            title: "Activity"
                        )
                    )
            }
        }
    }

    struct ExchangePreviewContainer: View {
        enum Tab: Hashable {
            case home
            case trade
            case portfolio
            case history
            case account
        }

        @State var activeTabIdentifier: AnyHashable

        var body: some View {
            TabBar(activeTabIdentifier: $activeTabIdentifier) {
                Text("Home")
                    .tabBarItem(
                        .tab(
                            identifier: Tab.home,
                            icon: .home,
                            title: "Home"
                        )
                    )

                Text("Trade")
                    .tabBarItem(
                        .tab(
                            identifier: Tab.trade,
                            icon: .swap,
                            title: "Trade"
                        )
                    )

                Text("Portfolio")
                    .tabBarItem(
                        .tab(
                            identifier: Tab.portfolio,
                            icon: .portfolio,
                            title: "Portfolio"
                        )
                    )

                Text("History")
                    .tabBarItem(
                        .tab(
                            identifier: Tab.history,
                            icon: .pending,
                            title: "History"
                        )
                    )

                Text("Account")
                    .tabBarItem(
                        .tab(
                            identifier: Tab.account,
                            icon: .user,
                            title: "Account"
                        )
                    )
            }
        }
    }
}

struct TabBarExamplesView_Previews: PreviewProvider {
    static var previews: some View {
        TabBarExamplesView()
    }
}
