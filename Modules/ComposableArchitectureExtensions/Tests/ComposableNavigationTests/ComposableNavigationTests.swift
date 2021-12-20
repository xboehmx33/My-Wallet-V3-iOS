import ComposableArchitecture
@testable import ComposableNavigation
import SwiftUI
import XCTest

final class ComposableNavigationTests: XCTestCase {

    func test_route() throws {

        var state = TestState()

        _ = testReducer.run(&state, .navigate(to: .test), ())
        XCTAssertEqual(state.route?.action, .navigateTo)
        XCTAssertEqual(state.route?.route, .test)

        _ = testReducer.run(&state, .enter(into: .story), ())
        XCTAssertEqual(state.route?.action, .enterInto(.default))
        XCTAssertEqual(state.route?.route, .story)

        _ = testReducer.run(&state, .dismiss(), ())
        XCTAssertNil(state.route)

        _ = testReducer.run(&state, .enter(into: .story, context: .fullScreen), ())
        XCTAssertEqual(state.route?.action, .enterInto(.fullScreen))
        XCTAssertEqual(state.route?.route, .story)

        _ = testReducer.run(&state, .dismiss(), ())
        XCTAssertNil(state.route)

        _ = testReducer.run(&state, .enter(into: .context("Context")), ())
        XCTAssertEqual(state.route?.action, .enterInto(.default))
        XCTAssertEqual(state.route?.route, .context("Context"))
    }
}

struct TestState: NavigationState {
    var route: RouteIntent<TestRoute>?
}

enum TestAction: NavigationAction {
    case route(RouteIntent<TestRoute>?)
}

enum TestRoute: NavigationRoute {

    case test
    case story
    case context(String)

    func destination(in store: Store<TestState, TestAction>) -> some View {
        Text(String(describing: self))
    }
}

let testReducer = Reducer<TestState, TestAction, Void> { state, action, _ in
    switch action {
    case .route(let route):
        state.route = route
        return .none
    }
}
