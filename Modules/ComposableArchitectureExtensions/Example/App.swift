// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import ComposableArchitecture
import ComposableNavigation
import SwiftUI

@main
struct Demo: App {
    var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView(
                    store: .init(
                        initialState: ExampleState(name: "Root"),
                        reducer: exampleReducer,
                        environment: ()
                    )
                )
            }
        }
    }
}

struct ExampleState: Equatable, NavigationState {
    var route: RouteIntent<ExampleRoute>?
    var name: String
    var lineage: [String] = []
    var end: EndState = .init(name: "End")
}

indirect enum ExampleAction: NavigationAction {
    case route(RouteIntent<ExampleRoute>?)
    case end(EndAction)
}

let exampleReducer = Reducer<ExampleState, ExampleAction, Void>
    .combine(
        .init { state, action, _ in
            switch action {
            case .route(let route):
                state.route = route
                return .none
            case .end:
                return .fireAndForget { print("✅") }
            }
        }
    )

enum ExampleRoute: NavigationRoute, CaseIterable {

    case a
    case b
    case c
    case end

    @ViewBuilder
    func destination(in store: Store<ExampleState, ExampleAction>) -> some View {
        let viewStore = ViewStore(store)
        switch self {
        case .a, .b, .c:
            ContentView(
                store: .init(
                    initialState: ExampleState(
                        name: String(describing: self),
                        lineage: viewStore.lineage + [viewStore.name]
                    ),
                    reducer: exampleReducer,
                    environment: ()
                )
            )
        case .end:
            EndContentView(
                store: .init(initialState: .init(name: "End"), reducer: endReducer, environment: .init(dismiss: { viewStore.send(.dismiss()) }))
            )
        }
    }
}

struct ContentView: View {

    let store: Store<ExampleState, ExampleAction>

    init(store: Store<ExampleState, ExampleAction>) {
        self.store = store
    }

    var body: some View {
        WithViewStore(store) { view in
            VStack(alignment: .leading) {
                Text(view.lineage.joined(separator: "."))
                Spacer()
                ForEach(ExampleRoute.allCases, id: \.self) { route in
                    Button("Navigate To → \(String(describing: route))") {
                        view.send(.navigate(to: route))
                    }
                }
                Spacer()
                ForEach(ExampleRoute.allCases, id: \.self) { route in
                    Button("Enter Into → \(String(describing: route))") {
                        view.send(.enter(into: route))
                    }
                }
                Spacer()
            }
            .navigationTitle(view.name)
            .navigationRoute(in: store)
        }
    }
}

struct EndEnvironment {
    var dismiss: () -> Void
}

struct EndState: Equatable {
    var name: String
}

enum EndAction {
    case dismiss
    case onAppear
}

let endReducer = Reducer<EndState, EndAction, EndEnvironment> { _, action, environment in
    switch action {
    case .dismiss:
        return .fireAndForget(environment.dismiss)
    case .onAppear:
        return .none
    }
}

struct EndContentView: View {

    let store: Store<EndState, EndAction>

    init(store: Store<EndState, EndAction>) {
        self.store = store
    }

    var body: some View {
        WithViewStore(store) { view in
            Text(view.name)
                .onAppear {
                    view.send(.onAppear)
                }
            Button("dismiss") {
                view.send(.dismiss)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(
            store: .init(
                initialState: ExampleState(name: "Root"),
                reducer: exampleReducer,
                environment: ()
            )
        )
    }
}
