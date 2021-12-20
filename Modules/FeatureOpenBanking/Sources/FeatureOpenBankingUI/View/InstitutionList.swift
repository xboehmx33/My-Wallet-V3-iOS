// Copyright © Blockchain Luxembourg S.A. All rights reserved.

#if canImport(SharedComponentLibrary)
import SharedComponentLibrary
typealias ComponentLibrarySecondaryButton = SharedComponentLibrary.SecondaryButton
#else
import ComponentLibrary
typealias ComponentLibrarySecondaryButton = ComponentLibrary.SecondaryButton
#endif
import ComposableArchitecture
import ComposableNavigation
import FeatureOpenBankingDomain
import SwiftUI
import ToolKit
import UIComponentsKit

public struct InstitutionListState: Equatable, NavigationState {

    public var route: RouteIntent<InstitutionListRoute>?

    var result: Result<OpenBanking.BankAccount, OpenBanking.Error>?
    var selection: ApproveState?
}

public enum InstitutionListAction: Hashable, NavigationAction, FailureAction {

    case route(RouteIntent<InstitutionListRoute>?)
    case failure(OpenBanking.Error)

    case fetch
    case fetched(OpenBanking.BankAccount)
    case select(OpenBanking.BankAccount, OpenBanking.Institution)
    case showTransferDetails

    case approve(ApproveAction)
    case dismiss
}

public enum InstitutionListRoute: CaseIterable, NavigationRoute {

    case approve

    @ViewBuilder
    public func destination(in store: Store<InstitutionListState, InstitutionListAction>) -> some View {
        switch self {
        case .approve:
            IfLetStore(
                store.scope(state: \.selection, action: InstitutionListAction.approve),
                then: ApproveView.init(store:)
            )
        }
    }
}

public let institutionListReducer = Reducer<InstitutionListState, InstitutionListAction, OpenBankingEnvironment>
    .combine(
        approveReducer
            .optional()
            .pullback(
                state: \.selection,
                action: /InstitutionListAction.approve,
                environment: \.environment
            ),
        .init { state, action, environment in
            switch action {
            case .route(let route):
                state.route = route
                return .none
            case .fetch:
                return environment.openBanking
                    .createBankAccount()
                    .receive(on: environment.scheduler)
                    .map(InstitutionListAction.fetched)
                    .catch(InstitutionListAction.failure)
                    .eraseToEffect()
            case .fetched(let account):
                state.result = .success(account)
                return .none
            case .showTransferDetails:
                return .fireAndForget(environment.showTransferDetails)
            case .select(let account, let institution):
                state.selection = .init(
                    bank: .init(
                        data: .init(account: account, action: .link(institution: institution))
                    )
                )
                return .navigate(to: .approve)
            case .approve(.deny):
                state.route = nil
                return .none
            case .approve(.bank(.cancel)):
                state.route = nil
                state.result = nil
                return Effect(value: .fetch)
            case .approve:
                return .none
            case .dismiss:
                return .fireAndForget(environment.dismiss)
            case .failure(let error):
                state.result = .failure(error)
                return .none
            }
        }
    )

public struct InstitutionList: View {

    private let store: Store<InstitutionListState, InstitutionListAction>

    @State private var loading: CGFloat = 44
    @State private var padding: CGFloat = 40

    public init(store: Store<InstitutionListState, InstitutionListAction>) {
        self.store = store
    }

    public var body: some View {
        WithViewStore(store.scope(state: \.result)) { viewStore in
            ZStack {
                switch viewStore.state {
                case .success(let account) where account.attributes.institutions != nil:
                    SearchableList(
                        account.attributes.institutions?.map(Item.init) ?? [],
                        placeholder: Localization.InstitutionList.search,
                        content: { bank in
                            Button(
                                action: {
                                    viewStore.send(.select(account, bank.institution))
                                },
                                label: { bank }
                            )
                        },
                        empty: {
                            NoSearchResults
                        }
                    )
                case .failure(let error):
                    InfoView(
                        .init(
                            media: .bankIcon,
                            overlay: .init(media: .error),
                            title: Localization.Error.title,
                            subtitle: "\(error.description)"
                        ),
                        in: .openBanking
                    )
                default:
                    ProgressView(value: 0.25)
                        .frame(width: 12.vmin, alignment: .center)
                        .aspectRatio(1, contentMode: .fit)
                        .progressViewStyle(IndeterminateProgressStyle())
                        .onAppear { viewStore.send(.fetch) }
                }
            }
            .navigationRoute(in: store)
            .navigationTitle(Localization.InstitutionList.title)
            .whiteNavigationBarStyle()
            .trailingNavigationButton(.close) {
                viewStore.send(.dismiss)
            }
        }
    }

    @ViewBuilder var NoSearchResults: some View {
        WithViewStore(store) { view in
            Spacer()
            Text(Localization.InstitutionList.Error.couldNotFindBank)
                .typography(.paragraph1)
                .foregroundColor(.textDetail)
                .frame(alignment: .center)
                .multilineTextAlignment(.center)
                .padding([.leading, .trailing], 12.5.vmin)
            Spacer()
            ComponentLibrarySecondaryButton(title: Localization.InstitutionList.Error.showTransferDetails) {
                view.send(.showTransferDetails)
            }
            .padding(10.5.vmin)
        }
    }
}

extension InstitutionList {

    public struct Item: View, Identifiable {

        let institution: OpenBanking.Institution

        public var id: Identity<OpenBanking.Institution> { institution.id }

        private var title: String { institution.fullName }
        private var image: URL? {
            institution.media.first(where: { $0.type == .icon })?.source
                ?? institution.media.first?.source
        }

        init(_ institution: OpenBanking.Institution) {
            self.institution = institution
        }

        public var body: some View {
            HStack {
                Group {
                    if let image = image {
                        ImageResourceView(
                            url: image,
                            placeholder: { Color.viewPrimaryBackground }
                        )
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                    } else {
                        Color.viewPrimaryBackground
                    }
                }
                .frame(width: 12.vw, height: 12.vw, alignment: .center)
                Text(title)
                    .typography(.body2)
                    .foregroundColor(.textTitle)
                Spacer()
                Image(systemName: "chevron.right")
                    .frame(width: 8.pt)
                    .padding()
                    .foregroundColor(.disclosureIndicator)
            }
            .frame(height: 9.5.vh, alignment: .center)
        }
    }
}

extension InstitutionList.Item: CustomStringConvertible {
    public var description: String { title }
}

#if DEBUG
struct InstitutionList_Previews: PreviewProvider {

    static var previews: some View {
        InstitutionList.Item(.mock)
        NavigationView {
            InstitutionList(
                store: Store<InstitutionListState, InstitutionListAction>(
                    initialState: InstitutionListState(),
                    reducer: institutionListReducer,
                    environment: .mock
                )
            )
            .ignoresSafeArea()
        }
    }
}
#endif
