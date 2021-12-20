#if canImport(SharedComponentLibrary)
import SharedComponentLibrary
#else
import ComponentLibrary
#endif
import ComposableArchitecture
import Localization
import SwiftUI
import UIKit

public struct BuyButtonView: View {
    public static let height: CGFloat = 80

    private let viewStore: ViewStore<BuyButtonState, BuyButtonAction>

    public init(store: Store<BuyButtonState, BuyButtonAction>) {
        viewStore = ViewStore(store)
    }

    public var body: some View {
        ZStack(alignment: .center) {
            Rectangle()
                .fill(verticalGradient)
                .frame(width: .infinity)

            VStack {
                Spacer()
                PrimaryButton(title: title) {
                    viewStore.send(.buyTapped)
                }
                .frame(width: .infinity, alignment: .center)
                .padding([.bottom], 16)
                .padding([.leading, .trailing], 24)
            }
        }.frame(width: .infinity, height: BuyButtonView.height)
    }

    private var title: String {
        guard let cryptoCurrency = viewStore.cryptoCurrency else {
            return LocalizationConstants.BuyButton.buyCrypto
        }

        return LocalizationConstants.BuyButton.buy(cryptoName: cryptoCurrency.name)
    }

    @ViewBuilder
    private var verticalGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.semantic.background.opacity(0),
                Color.semantic.background
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

struct BuyButtonView_Previews: PreviewProvider {
    static var previews: some View {
        EmptyView()
    }
}
