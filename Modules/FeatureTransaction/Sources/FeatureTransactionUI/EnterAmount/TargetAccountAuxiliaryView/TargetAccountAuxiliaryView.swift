// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import ComposableArchitecture
import Localization
import MoneyKit
import PlatformKit
import SwiftUI
import UIComponentsKit

struct TargetAccountAuxiliaryViewState: Equatable {
    let image: ImageResource
    let title: String
    let subtitle: String
    let enabled: Bool
}

enum TargetAccountAuxiliaryViewAction: Equatable {
    case tap
}

struct TargetAccountAuxiliaryViewEnvironment {
    let onTap: () -> Void
}

let targetAccountAuxiliaryViewReducer = Reducer<
    TargetAccountAuxiliaryViewState,
    TargetAccountAuxiliaryViewAction,
    TargetAccountAuxiliaryViewEnvironment
> { _, action, environment in
    switch action {
    case .tap:
        environment.onTap()
    }
    return .none
}

struct TargetAccountAuxiliaryView: View {

    enum Constants {
        static let accountImageSize: CGFloat = 34
        static let disclosureIndicatorSize: CGFloat = 16
    }

    let store: Store<TargetAccountAuxiliaryViewState, TargetAccountAuxiliaryViewAction>

    var body: some View {
        WithViewStore(store) { viewStore in
            Button(
                action: {
                    viewStore.send(.tap)
                },
                label: {
                    HStack(
                        alignment: .center,
                        spacing: LayoutConstants.VerticalSpacing.betweenContentGroups
                    ) {
                        ImageResourceView(viewStore.image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: Constants.accountImageSize)
                        VStack(alignment: .leading, spacing: 0) {
                            Text(viewStore.title)
                                .textStyle(.heading)
                                .multilineTextAlignment(.leading)
                            Text(viewStore.subtitle)
                                .textStyle(.subheading)
                                .multilineTextAlignment(.leading)
                        }
                        if viewStore.enabled {
                            Spacer()
                            Image("icon-disclosure-down-small", bundle: .platformUIKit)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: Constants.disclosureIndicatorSize)
                        }
                    }
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
                    .padding()
                }
            )
            .disabled(!viewStore.enabled)
            .buttonStyle(BorderlessButtonStyle())
        }
    }
}

extension TargetAccountAuxiliaryView {

    init(asset: CryptoCurrency, price: MoneyValue, action: @escaping () -> Void) {
        self.init(
            store: .init(
                initialState: TargetAccountAuxiliaryViewState(
                    image: asset.logoResource,
                    title: asset.name,
                    subtitle: LocalizationConstants.Transaction.Buy.AmountPresenter.value(
                        for: asset.displayCode,
                        price: price.displayString
                    ),
                    enabled: true
                ),
                reducer: targetAccountAuxiliaryViewReducer,
                environment: TargetAccountAuxiliaryViewEnvironment(
                    onTap: action
                )
            )
        )
    }
}

#if DEBUG
struct TargetAccountAuxiliaryView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(alignment: .leading) {
            TargetAccountAuxiliaryView(
                asset: .coin(.bitcoin),
                price: .init(amount: 2307477, currency: .fiat(.GBP)),
                action: {}
            )
            Spacer()
        }
    }
}
#endif
