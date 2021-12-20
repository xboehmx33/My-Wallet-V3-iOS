// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import CombineSchedulers
import DIKit
import MoneyKit
import PlatformKit

public struct TourEnvironment {

    let mainQueue: AnySchedulerOf<DispatchQueue>
    let enabledCurrenciesService: EnabledCurrenciesServiceAPI

    var createAccountAction: () -> Void
    var restoreAction: () -> Void
    var logInAction: () -> Void

    public init(
        mainQueue: AnySchedulerOf<DispatchQueue> = .main,
        enabledCurrenciesService: EnabledCurrenciesServiceAPI = resolve(),
        createAccountAction: @escaping () -> Void,
        restoreAction: @escaping () -> Void,
        logInAction: @escaping () -> Void
    ) {
        self.mainQueue = mainQueue
        self.enabledCurrenciesService = enabledCurrenciesService
        self.createAccountAction = createAccountAction
        self.restoreAction = restoreAction
        self.logInAction = logInAction
    }
}
