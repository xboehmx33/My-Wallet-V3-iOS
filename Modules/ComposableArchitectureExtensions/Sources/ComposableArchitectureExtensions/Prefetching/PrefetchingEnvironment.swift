// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Foundation

/// Environment for passing scheduling queue used for debouncing, overridable for testing.
public struct PrefetchingEnvironment {
    let mainQueue: AnySchedulerOf<DispatchQueue>

    public init(
        mainQueue: AnySchedulerOf<DispatchQueue>
    ) {
        self.mainQueue = mainQueue
    }
}
