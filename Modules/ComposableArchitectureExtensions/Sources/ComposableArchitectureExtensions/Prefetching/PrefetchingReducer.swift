// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Algorithms
import Foundation

/// Prefetching reducer to combine with your existing reducer.
///
/// eg:
///
///     myReducer.combined(
///         with: PrefetchingReducer(
///             state: \MyState.prefetching,
///             action: /MyAction.prefetching,
///             environment: { .init(mainQueue: $0.mainQueue) }
///         )
///     )
///
/// - Parameters:
///   - state: Writeable key path for your state to the Prefetching state
///   - action: Case path mapping your action to Prefetching actions
///   - environment: Map of global environment to Prefetching environment
/// - Returns: A composable Reducer typed to your state, action, and environment.
public func PrefetchingReducer<GlobalState, GlobalAction, GlobalEnvironment>(
    state: WritableKeyPath<GlobalState, PrefetchingState>,
    action: CasePath<GlobalAction, PrefetchingAction>,
    environment: @escaping (GlobalEnvironment) -> PrefetchingEnvironment
) -> Reducer<GlobalState, GlobalAction, GlobalEnvironment> {
    Reducer { state, action, environment in

        switch action {

        case .onAppear(index: let index):
            state.visibleElements.insert(index)
            return Effect(value: .fetchIfNeeded)
                .debounce(id: FetchId(), for: state.debounce, scheduler: environment.mainQueue)

        case .onDisappear(index: let index):
            state.visibleElements.remove(index)
            return Effect(value: .fetchIfNeeded)
                .debounce(id: FetchId(), for: state.debounce, scheduler: environment.mainQueue)

        case .requeue(indices: let indices):
            state.fetchedIndices.subtract(indices)
            return Effect(value: .fetchIfNeeded)
                .debounce(id: FetchId(), for: state.debounce, scheduler: environment.mainQueue)

        case .fetchIfNeeded:
            guard let (min, max) = state.visibleElements.minAndMax() else {
                return .none
            }

            var range: Range<Int> = min..<(max + 1)

            if let validIndices = state.validIndices {
                range = range.expanded(by: state.fetchMargin).clamped(to: validIndices)
            }

            let indicesToFetch = Set(range).subtracting(state.fetchedIndices)
            if indicesToFetch.isEmpty {
                return .none
            } else {
                return Effect(
                    value: .fetch(
                        indices: indicesToFetch
                    )
                )
            }

        case .fetch(indices: let indices):
            state.fetchedIndices.formUnion(indices)
            return .none
        }
    }
    .pullback(state: state, action: action, environment: environment)
}

// MARK: - Private

private struct FetchId: Hashable {}

extension Range where Bound: AdditiveArithmetic {

    /// Returns a copy of this range, extended outwards by the margin in both directions.
    ///
    /// For example:
    ///
    ///     let x: Range = 10..<20
    ///     print(x.expanded(by: 10))
    ///     // Prints "0..<30"
    func expanded(by margin: Bound) -> Self {
        (lowerBound - margin)..<(upperBound + margin)
    }
}
