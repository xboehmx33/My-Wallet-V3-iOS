// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import ComponentLibrary
import SwiftUI

struct BottomSheetExamples: View {

    @State var isPresented: Bool = true

    var body: some View {
        Button("Tap to open") {
            isPresented.toggle()
        }
        .bottomSheet(isPresented: $isPresented) {
            Group {
                PrimaryRow(
                    title: "Swap",
                    subtitle: "Exchange for Another Crypto",
                    leading: {
                        Icon.send.frame(width: 30, height: 30)
                    }
                )

                PrimaryDivider()
            }

            Group {
                PrimaryRow(
                    title: "Send",
                    subtitle: "Send to Any Wallet",
                    leading: {
                        Icon.send.frame(width: 30, height: 30)
                    }
                )

                PrimaryDivider()
            }

            Group {
                PrimaryRow(
                    title: "Receive",
                    subtitle: "Copy Your Address & QR Codes",
                    leading: {
                        Icon.send.frame(width: 30, height: 30)
                    }
                )

                PrimaryDivider()
            }

            Group {
                PrimaryRow(
                    title: "Rewards",
                    subtitle: "Earn Rewards on Your Crypto",
                    leading: {
                        Icon.send.frame(width: 30, height: 30)
                    }
                )

                PrimaryDivider()
            }

            Group {
                PrimaryRow(
                    title: "Add Cash",
                    subtitle: "Add Cash from Your Bank",
                    leading: {
                        Icon.send.frame(width: 30, height: 30)
                    }
                )

                PrimaryDivider()
            }

            PrimaryRow(
                title: "Cash Out",
                subtitle: "Withdraw Cash to Your Bank",
                leading: {
                    Icon.send.frame(width: 30, height: 30)
                }
            )

            HStack {
                PrimaryButton(title: "Buy", action: {})

                SecondaryButton(title: "Sell", action: {})
            }
            .padding(Spacing.padding())
        }
        .ignoresSafeArea()
    }
}

struct BottomSheetExamples_Previews: PreviewProvider {
    static var previews: some View {
        BottomSheetExamples()
    }
}
