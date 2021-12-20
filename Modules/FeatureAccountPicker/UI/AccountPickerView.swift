import Combine
import ComposableArchitecture
import ComposableArchitectureExtensions
import FeatureAccountPickerDomain
import Localization
import SwiftUI
import UIComponentsKit

public struct AccountPickerView<
    BadgeView: View,
    IconView: View,
    MultiBadgeView: View,
    WithdrawalLocksView: View
>: View {

    // MARK: - Internal properties

    let store: Store<AccountPickerState, AccountPickerAction>
    @ViewBuilder let badgeView: (AnyHashable) -> BadgeView
    @ViewBuilder let iconView: (AnyHashable) -> IconView
    @ViewBuilder let multiBadgeView: (AnyHashable) -> MultiBadgeView
    @ViewBuilder let withdrawalLocksView: () -> WithdrawalLocksView

    // MARK: - Private properties

    @State private var isSearching: Bool = false

    // MARK: - Init

    init(
        store: Store<AccountPickerState, AccountPickerAction>,
        @ViewBuilder badgeView: @escaping (AnyHashable) -> BadgeView,
        @ViewBuilder iconView: @escaping (AnyHashable) -> IconView,
        @ViewBuilder multiBadgeView: @escaping (AnyHashable) -> MultiBadgeView,
        @ViewBuilder withdrawalLocksView: @escaping () -> WithdrawalLocksView
    ) {
        self.store = store
        self.badgeView = badgeView
        self.iconView = iconView
        self.multiBadgeView = multiBadgeView
        self.withdrawalLocksView = withdrawalLocksView
    }

    public init(
        environment: AccountPickerEnvironment,
        @ViewBuilder badgeView: @escaping (AnyHashable) -> BadgeView,
        @ViewBuilder iconView: @escaping (AnyHashable) -> IconView,
        @ViewBuilder multiBadgeView: @escaping (AnyHashable) -> MultiBadgeView,
        @ViewBuilder withdrawalLocksView: @escaping () -> WithdrawalLocksView
    ) {
        self.init(
            store: Store(
                initialState: AccountPickerState(
                    rows: .loading,
                    header: .init(headerStyle: .none, searchText: nil),
                    fiatBalances: [:],
                    cryptoBalances: [:],
                    currencyCodes: [:]
                ),
                reducer: accountPickerReducer,
                environment: environment
            ),
            badgeView: badgeView,
            iconView: iconView,
            multiBadgeView: multiBadgeView,
            withdrawalLocksView: withdrawalLocksView
        )
    }

    // MARK: - Body

    public var body: some View {
        StatefulView(
            store: store.scope(state: \.rows),
            loadedAction: AccountPickerAction.rowsLoaded,
            loadingAction: AccountPickerAction.rowsLoading,
            successAction: LoadedRowsAction.success,
            failureAction: LoadedRowsAction.failure,
            loading: { _ in
                LoadingStateView(title: "")
            },
            success: { successStore in
                WithViewStore(successStore.scope { $0.content.isEmpty }) { viewStore in
                    if viewStore.state {
                        EmptyStateView(
                            title: LocalizationConstants.AccountPicker.noWallets,
                            subHeading: "",
                            image: ImageAsset.emptyActivity.image
                        )
                    } else {
                        contentView(successStore: successStore)
                    }
                }
            },
            failure: { _ in
                ErrorStateView(title: LocalizationConstants.Errors.genericError)
            }
        )
        .onAppear {
            ViewStore(store).send(.subscribeToUpdates)
        }
    }

    @ViewBuilder func contentView(
        successStore: Store<Rows, SuccessRowsAction>
    ) -> some View {
        VStack(spacing: .zero) {
            WithViewStore(store.scope { $0.header }) { viewStore in
                HeaderView(
                    viewModel: viewStore.headerStyle,
                    searchText: Binding<String?>(
                        get: { viewStore.searchText },
                        set: { viewStore.send(.search($0)) }
                    ),
                    isSearching: $isSearching
                )
            }
            List {
                WithViewStore(
                    successStore,
                    removeDuplicates: { $0.identifier == $1.identifier },
                    content: { viewStore in
                        ForEach(Array(zip(viewStore.content.indices, viewStore.content)), id: \.1.id) { index, row in
                            WithViewStore(self.store.scope { $0.balances(for: row.id) }) { balancesStore in
                                AccountPickerRowView(
                                    model: row,
                                    send: viewStore.send,
                                    badgeView: badgeView,
                                    iconView: iconView,
                                    multiBadgeView: multiBadgeView,
                                    withdrawalLocksView: withdrawalLocksView,
                                    fiatBalance: balancesStore.fiat,
                                    cryptoBalance: balancesStore.crypto,
                                    currencyCode: balancesStore.currencyCode
                                )
                                .onAppear {
                                    ViewStore(store)
                                        .send(.prefetching(.onAppear(index: index)))
                                }
                                .onDisappear {
                                    ViewStore(store)
                                        .send(.prefetching(.onDisappear(index: index)))
                                }
                            }
                        }
                    }
                )
                .listRowInsets(EdgeInsets())
            }
            .environment(\.defaultMinListRowHeight, 0)
            .animation(.easeInOut, value: isSearching)
        }
    }
}

struct AccountPickerView_Previews: PreviewProvider {
    static let allIdentifier = UUID()
    static let btcWalletIdentifier = UUID()
    static let btcTradingWalletIdentifier = UUID()
    static let ethWalletIdentifier = UUID()
    static let bchWalletIdentifier = UUID()
    static let bchTradingWalletIdentifier = UUID()

    static let fiatBalances: [AnyHashable: String] = [
        allIdentifier: "$2,302.39",
        btcWalletIdentifier: "$2,302.39",
        btcTradingWalletIdentifier: "$10,093.13",
        ethWalletIdentifier: "$807.21",
        bchWalletIdentifier: "$807.21",
        bchTradingWalletIdentifier: "$40.30"
    ]

    static let currencyCodes: [AnyHashable: String] = [
        allIdentifier: "USD"
    ]

    static let cryptoBalances: [AnyHashable: String] = [
        btcWalletIdentifier: "0.21204887 BTC",
        btcTradingWalletIdentifier: "1.38294910 BTC",
        ethWalletIdentifier: "0.17039384 ETH",
        bchWalletIdentifier: "0.00388845 BCH",
        bchTradingWalletIdentifier: "0.00004829 BCH"
    ]

    static let accountPickerRowList: [AccountPickerRow] = [
        .accountGroup(
            AccountPickerRow.AccountGroup(
                id: allIdentifier,
                title: "All Wallets",
                description: "Total Balance"
            )
        ),
        .button(
            AccountPickerRow.Button(
                id: UUID(),
                text: "See Balance"
            )
        ),
        .singleAccount(
            AccountPickerRow.SingleAccount(
                id: btcWalletIdentifier,
                title: "BTC Wallet",
                description: "Bitcoin"
            )
        ),
        .singleAccount(
            AccountPickerRow.SingleAccount(
                id: btcTradingWalletIdentifier,
                title: "BTC Trading Wallet",
                description: "Bitcoin"
            )
        ),
        .singleAccount(
            AccountPickerRow.SingleAccount(
                id: ethWalletIdentifier,
                title: "ETH Wallet",
                description: "Ethereum"
            )
        ),
        .singleAccount(
            AccountPickerRow.SingleAccount(
                id: bchWalletIdentifier,
                title: "BCH Wallet",
                description: "Bitcoin Cash"
            )
        ),
        .singleAccount(
            AccountPickerRow.SingleAccount(
                id: bchTradingWalletIdentifier,
                title: "BCH Trading Wallet",
                description: "Bitcoin Cash"
            )
        )
    ]

    static let header = AccountPickerState.HeaderState(
        headerStyle: .normal(
            title: "Send Crypto Now",
            subtitle: "Choose a Wallet to send cypto from.",
            image: ImageAsset.iconSend.image,
            tableTitle: "Select a Wallet",
            searchable: false
        ),
        searchText: nil
    )

    @ViewBuilder static func view(
        rows: LoadingState<Result<Rows, AccountPickerError>>
    ) -> some View {
        AccountPickerView(
            store: Store(
                initialState: AccountPickerState(
                    rows: rows,
                    header: header,
                    fiatBalances: fiatBalances,
                    cryptoBalances: cryptoBalances,
                    currencyCodes: currencyCodes
                ),
                reducer: accountPickerReducer,
                environment: AccountPickerEnvironment(
                    rowSelected: { _ in },
                    backButtonTapped: {},
                    closeButtonTapped: {},
                    search: { _ in },
                    sections: { Just(Array(accountPickerRowList)).eraseToAnyPublisher() },
                    updateSingleAccounts: { _ in .just([:]) },
                    updateAccountGroups: { _ in .just([:]) },
                    header: { Just(header.headerStyle).setFailureType(to: Error.self).eraseToAnyPublisher() }
                )
            ),
            badgeView: { _ in EmptyView() },
            iconView: { _ in EmptyView() },
            multiBadgeView: { _ in EmptyView() },
            withdrawalLocksView: { EmptyView() }
        )
    }

    static var previews: some View {
        view(rows: .loaded(next: .success(Rows(content: accountPickerRowList))))
            .previewDisplayName("Success")

        view(rows: .loaded(next: .success(Rows(content: []))))
            .previewDisplayName("Empty")

        view(rows: .loaded(next: .failure(.testError)))
            .previewDisplayName("Error")

        view(rows: .loading)
            .previewDisplayName("Loading")
    }
}
