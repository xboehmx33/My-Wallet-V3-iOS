//  Copyright © 2021 Blockchain Luxembourg S.A. All rights reserved.

#if canImport(SharedComponentLibrary)
import SharedComponentLibrary
#else
import ComponentLibrary
#endif
import Localization
import SwiftUI
import ToolKit

struct FrequentAction: Hashable, Identifiable {
    var id: Tag { tag }
    let tag: Tag
    let name: String
    let icon: Icon
    let description: String
}

extension FrequentAction {

    typealias Localization = LocalizationConstants.FrequentActionItem

    static let swap = FrequentAction(
        tag: blockchain.ux.user.fab.swap,
        name: Localization.swap.name,
        icon: .walletSwap,
        description: Localization.swap.description
    )
    static let send = FrequentAction(
        tag: blockchain.ux.user.fab.send,
        name: Localization.send.name,
        icon: .walletSend,
        description: Localization.send.description
    )
    static let receive = FrequentAction(
        tag: blockchain.ux.user.fab.receive,
        name: Localization.receive.name,
        icon: .walletReceive,
        description: Localization.receive.description
    )
    static let rewards = FrequentAction(
        tag: blockchain.ux.user.fab.rewards,
        name: Localization.rewards.name,
        icon: .walletPercent,
        description: Localization.rewards.description
    )
    static let deposit = FrequentAction(
        tag: blockchain.ux.user.fab.deposit,
        name: Localization.deposit.name,
        icon: .walletDeposit,
        description: Localization.deposit.description
    )
    static let withdraw = FrequentAction(
        tag: blockchain.ux.user.fab.withdraw,
        name: Localization.withdraw.name,
        icon: .walletWithdraw,
        description: Localization.withdraw.description
    )
    static let buy = FrequentAction(
        tag: blockchain.ux.user.fab.buy,
        name: Localization.buy,
        icon: .walletBuy,
        description: Localization.buy
    )
    static let sell = FrequentAction(
        tag: blockchain.ux.user.fab.sell,
        name: Localization.sell,
        icon: .walletSell,
        description: Localization.sell
    )
}

struct FrequentActionView: View {

    var list: [FrequentAction]
    var buttons: [FrequentAction]

    var action: (FrequentAction) -> Void

    init(
        list: [FrequentAction] = [
            .swap,
            .send,
            .receive,
            .rewards
        ],
        buttons: [FrequentAction] = [
            .buy,
            .sell
        ],
        action: @escaping (FrequentAction) -> Void
    ) {
        self.list = list
        self.buttons = buttons
        self.action = action
    }

    var body: some View {
        ForEach(list.indexed(), id: \.element) { index, item in
            VStack(alignment: .leading, spacing: 0) {
                if index != list.startIndex {
                    PrimaryDivider()
                        .padding(.leading, 72.pt)
                }
                PrimaryRow(
                    title: item.name,
                    subtitle: item.description,
                    leading: {
                        item.icon.circle()
                            .accentColor(.semantic.primary)
                            .frame(width: 32.pt)
                    }
                )
                .onTapGesture {
                    action(item)
                }
                .identity(item.tag)
            }
        }
        HStack(spacing: 8.pt) {
            ForEach(buttons) { button in
                switch button.tag {
                case blockchain.ux.user.fab.buy:
                    PrimaryButton(
                        title: button.name,
                        action: { action(button) }
                    )
                default:
                    SecondaryButton(
                        title: button.name,
                        action: { action(button) }
                    )
                }
            }
        }
        .padding([.top, .bottom])
        .padding([.leading, .trailing], 24.pt)
    }
}

extension FrequentActionView {

    init(
        list: [Tag.Meme],
        buttons: [Tag.Meme],
        action: @escaping (FrequentAction) -> Void
    ) {
        self.init(
            list: list.compactMap(My.data),
            buttons: buttons.compactMap(My.data),
            action: action
        )
    }

    private static func data(_ tag: Tag.Meme) -> FrequentAction? {
        switch tag {
        case blockchain.ux.user.fab.buy[]:
            return .buy
        case blockchain.ux.user.fab.sell[]:
            return .sell
        case blockchain.ux.user.fab.swap[]:
            return .swap
        case blockchain.ux.user.fab.send[]:
            return .send
        case blockchain.ux.user.fab.receive[]:
            return .receive
        case blockchain.ux.user.fab.rewards[]:
            return .rewards
        default:
            return nil
        }
    }
}
