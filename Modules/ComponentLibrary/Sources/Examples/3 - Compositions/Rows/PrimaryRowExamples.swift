// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import ComponentLibrary
import SwiftUI

// swiftlint:disable line_length
struct PrimaryRowExamplesView: View {

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                Group {
                    PrimaryRow(
                        title: "Trading",
                        subtitle: "Buy & Sell"
                    )

                    PrimaryDivider()

                    PrimaryRow(
                        title: "Email Address",
                        subtitle: "satoshi@blockchain.com",
                        tags: [Tag(text: "Confirmed", variant: .success)]
                    )

                    PrimaryDivider()
                }

                Group {
                    PrimaryRow(
                        title: "From: BTC Trading Account",
                        subtitle: "To: 0x093871209487120934812"
                    )

                    PrimaryDivider()

                    PrimaryRow(
                        title: "Link a Bank",
                        subtitle: "Instant Connection",
                        description: "Securely link a bank to buy crypto, deposit cash and withdraw back to your bank at anytime.",
                        tags: [
                            Tag(text: "Fastest", variant: .success),
                            Tag(text: "Warning Alert", variant: .warning)
                        ]
                    )

                    PrimaryDivider()

                    PrimaryRow(
                        title: "Cloud Backup",
                        subtitle: "Buy & Sell",
                        trailing: {
                            Switch()
                        }
                    )

                    PrimaryDivider()

                    PrimaryRow(
                        title: "Features and Limits"
                    )
                }

                Group {

                    PrimaryDivider()

                    PrimaryRow(
                        title: "Back Up Your Wallet",
                        subtitle: "Step 1",
                        leading: {
                            Icon.wallet
                                .fixedSize()
                                .accentColor(Color.semantic.dark)
                        }
                    )

                    PrimaryDivider()

                    PrimaryRow(
                        title: "Gold Level",
                        subtitle: "Higher Trading Limits",
                        tags: [Tag(text: "Approved", variant: .success)],
                        leading: {
                            Icon.apple
                                .fixedSize()
                                .accentColor(.semantic.orangeBG)
                        }
                    )

                    PrimaryDivider()

                    PrimaryRow(
                        title: "Trade",
                        subtitle: "BTC -> ETH",
                        leading: {
                            Icon.trade
                                .fixedSize()
                                .accentColor(.semantic.success)
                        }
                    )

                    PrimaryDivider()

                    PrimaryRow(
                        title: "Link a Bank",
                        subtitle: "Instant Connection",
                        description: "Securely link a bank to buy crypto, deposit cash and withdraw back to your bank at anytime.",
                        tags: [
                            Tag(text: "Fastest", variant: .success),
                            Tag(text: "Warning Alert", variant: .warning)
                        ],
                        leading: {
                            Icon.bank
                                .fixedSize()
                                .accentColor(.semantic.primary)
                        }
                    )

                    PrimaryDivider()

                    PrimaryRow(
                        title: "Features and Limits",
                        leading: {
                            Icon.blockchain
                                .fixedSize()
                                .accentColor(.semantic.primary)
                        }
                    )
                }
            }
        }
    }

    private struct Switch: View {
        @State var isOn: Bool = false

        var body: some View {
            PrimarySwitch(
                variant: .green,
                accessibilityLabel: "Test",
                isOn: $isOn
            )
        }
    }
}

struct PrimaryRowExamplesView_Previews: PreviewProvider {
    static var previews: some View {
        PrimaryRowExamplesView()
    }
}
