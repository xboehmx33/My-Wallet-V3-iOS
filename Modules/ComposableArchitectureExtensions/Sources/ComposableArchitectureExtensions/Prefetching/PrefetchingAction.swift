// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Foundation

/// Actions for prefetching. See specific case documentation.
public enum PrefetchingAction: Equatable {

    /// Send this action when your list item appears
    case onAppear(index: Int)

    /// Send this action when your list item disappears
    case onDisappear(index: Int)

    /// Send this action if you encounter an error fetching, and wish to re-queue a set of indices.
    case requeue(indices: Set<Int>)

    /// Subscribe to this action in your reducer to run your Effects for fetching data.
    case fetch(indices: Set<Int>)

    /// Internal action used for debouncing & deferring calculations.
    case fetchIfNeeded
}
