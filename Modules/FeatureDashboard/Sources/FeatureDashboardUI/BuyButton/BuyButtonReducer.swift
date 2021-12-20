import ComposableArchitecture
import MoneyKit

let buyButtonReducer = Reducer<
    BuyButtonState,
    BuyButtonAction,
    BuyButtonEnvironment
> { state, action, environment in

    switch action {
    case .buyTapped:
        let cryptoCurrency: CryptoCurrency = state.cryptoCurrency ?? .coin(.bitcoin)

        return .fireAndForget {
            environment.walletOperationsRouter.handleBuyCrypto(currency: cryptoCurrency)
        }
    }
}
