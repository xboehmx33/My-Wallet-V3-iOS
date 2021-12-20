// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Foundation

// swiftlint:disable file_length
// swiftlint:disable line_length

extension LocalizationConstants {
    public enum Transaction {
        public enum TargetSource {
            public enum Radio {}
            public enum Card {}
        }

        public enum Confirmation {
            public enum Error {}
        }

        public enum Receive {
            public enum KYC {}
        }

        public enum Sign {
            public enum Completion {
                public enum Pending {}
                public enum Success {}
                public enum Failure {}
            }
        }

        public enum Send {
            public enum AmountPresenter {
                public enum LimitView {}
            }

            public enum Completion {
                public enum Pending {}
                public enum Success {}
                public enum Failure {}
            }
        }

        public enum Buy {
            public enum AmountPresenter {
                public enum LimitView {}
            }

            public enum Completion {
                public enum InProgress {}
                public enum Pending {}
                public enum Success {}
                public enum Failure {}
            }
        }

        public enum Sell {
            public enum Completion {
                public enum Pending {}
                public enum Success {}
                public enum Failure {}
            }

            public enum AmountPresenter {
                public enum LimitView {}
            }
        }

        public enum Withdraw {
            public enum Completion {
                public enum Pending {}
                public enum Success {}
                public enum Failure {}
            }
        }

        public enum Deposit {
            public enum Completion {
                public enum Pending {}
                public enum Success {}
                public enum Failure {}
            }
        }

        public enum Transfer {
            public enum ToS {}
            public enum Completion {
                public enum Pending {}
                public enum Success {}
                public enum Failure {}
            }
        }

        public enum InterestWithdraw {
            public enum Completion {
                public enum Pending {}
                public enum Success {}
                public enum Failure {}
            }
        }

        public enum Swap {
            public enum KYC {}
            public enum Completion {
                public enum Pending {}
                public enum Success {}
                public enum Failure {}
            }

            public enum AmountPresenter {
                public enum LimitView {}
            }
        }

        public enum TradingCurrency {}

        public enum Error {}
    }
}

extension LocalizationConstants.Transaction.Buy.AmountPresenter {

    public static func value(for assetCode: String, price formattedPrice: String) -> String {
        String(
            format: NSLocalizedString("1 %@ = %@", comment: "1 BTC = $30,000.00"),
            assetCode,
            formattedPrice
        )
    }
}

extension LocalizationConstants.Transaction.Buy.AmountPresenter.LimitView {
    public static let useMin = NSLocalizedString(
        "The minimum buy is %@",
        comment: "The minimum buy is $X.XX"
    )
    public static let useMax = NSLocalizedString(
        "You can buy up to %@",
        comment: "You can buy up to $X.XX"
    )
}

extension LocalizationConstants.Transaction.TargetSource.Radio {
    public static let accountEndingIn = NSLocalizedString("Account Ending in", comment: "Account Ending in")
    public static let minimum = NSLocalizedString("Minimum", comment: "Minimum")
    public static let free = NSLocalizedString("Free", comment: "Free")
    public static let fee = NSLocalizedString("Fee", comment: "Fee")
}

extension LocalizationConstants.Transaction.Swap.AmountPresenter.LimitView {
    public static let useMin = NSLocalizedString(
        "The minimum swap is %@",
        comment: "The minimum swap is"
    )
    public static let useMax = NSLocalizedString(
        "You can swap up to %@",
        comment: "You can swap up to"
    )
}

extension LocalizationConstants.Transaction.Sell.AmountPresenter.LimitView {
    public static let useMin = NSLocalizedString(
        "The minimum sell is %@",
        comment: "The minimum sell is"
    )
    public static let useMax = NSLocalizedString(
        "You can sell up to %@",
        comment: "You can sell up to"
    )
}

extension LocalizationConstants.Transaction.Receive.KYC {

    public static let title = NSLocalizedString(
        "Verify to use the Trading Account",
        comment: ""
    )
    public static let subtitle = NSLocalizedString(
        "Get access to the Trading Account in seconds by completing your profile and getting Silver access.",
        comment: ""
    )
    public static let card1Title = NSLocalizedString(
        "Verify Your Email",
        comment: ""
    )
    public static let card1Subtitle = NSLocalizedString(
        "Confirm your email address to protect your Blockchain.com Wallet.",
        comment: ""
    )
    public static let card2Title = NSLocalizedString(
        "Add Your Name & Address",
        comment: ""
    )
    public static let card2Subtitle = NSLocalizedString(
        "We need to know your name and address to comply with local laws.",
        comment: ""
    )
    public static let card3Title = NSLocalizedString(
        "Use the Trading Account",
        comment: ""
    )
    public static let card3Subtitle = NSLocalizedString(
        "Send, Receive, Buy and Swap cryptocurrencies with your Trading Account.",
        comment: ""
    )
    public static let verifyNow = NSLocalizedString(
        "Verify Now",
        comment: ""
    )
}

extension LocalizationConstants.Transaction.Swap.KYC {

    public static let overSilverLimitWarning = NSLocalizedString(
        "Tap here to upgrade your profile and swap this amount.",
        comment: "Tap here to upgrade your profile and swap this amount."
    )
    public static let title = NSLocalizedString(
        "Verify Your Email & Swap Today.",
        comment: ""
    )
    public static let subtitle = NSLocalizedString(
        "Get access to swap in seconds by completing your profile and getting Silver access.",
        comment: ""
    )
    public static let card1Title = NSLocalizedString(
        "Verify Your Email",
        comment: ""
    )
    public static let card1Subtitle = NSLocalizedString(
        "Confirm your email address to protect your Blockchain.com Wallet.",
        comment: ""
    )
    public static let card2Title = NSLocalizedString(
        "Add Your Name and Address",
        comment: ""
    )
    public static let card2Subtitle = NSLocalizedString(
        "We need to know your name and address to comply with local laws.",
        comment: ""
    )
    public static let card3Title = NSLocalizedString(
        "Start Swapping",
        comment: ""
    )
    public static let card3Subtitle = NSLocalizedString(
        "Instantly exchange your crypto.",
        comment: ""
    )
    public static let verifyNow = NSLocalizedString(
        "Verify Now",
        comment: ""
    )
}

extension LocalizationConstants.Transaction {

    public static let viewActivity = NSLocalizedString("View Activity", comment: "View Activity")
    public static let transfer = NSLocalizedString("Transfer", comment: "Transfer")
    public static let deposit = NSLocalizedString("Deposit", comment: "Deposit")
    public static let sell = NSLocalizedString("Sell", comment: "Sell")
    public static let send = NSLocalizedString("Send", comment: "Send")
    public static let swap = NSLocalizedString("Swap", comment: "Swap")
    public static let withdraw = NSLocalizedString("Withdraw", comment: "Withdraw")
    public static let buy = NSLocalizedString("Buy", comment: "Buy")

    public static let max = NSLocalizedString("Max", comment: "Max")

    public static let savings = NSLocalizedString("Savings", comment: "Savings")
    public static let checking = NSLocalizedString("Checking", comment: "Checking")
    public static let account = NSLocalizedString("Account", comment: "Account")

    public static let next = NSLocalizedString(
        "Next",
        comment: "Next"
    )
    public static let preview = NSLocalizedString(
        "Preview %@",
        comment: "Preview [Transaction Type]"
    )
    public static let receive = NSLocalizedString(
        "Receive",
        comment: "Receive"
    )
    public static let available = NSLocalizedString(
        "Available",
        comment: "Available"
    )
    public static let networkFee = NSLocalizedString("Network Fee", comment: "Network Fee")
    public static let newSwap = NSLocalizedString(
        "New Swap",
        comment: "New Swap"
    )
    public static let from = NSLocalizedString(
        "From",
        comment: "From"
    )
    public static let to = NSLocalizedString(
        "To",
        comment: "To"
    )
    public static let selectAWallet = NSLocalizedString(
        "Select a Wallet",
        comment: "Select a Wallet"
    )
    public static let orSelectAWallet = NSLocalizedString(
        "or Select a Wallet",
        comment: "Select a Wallet"
    )
}

extension LocalizationConstants.Transaction.Withdraw {
    public static let withdrawNow = NSLocalizedString(
        "Withdraw Now",
        comment: "Withdraw Now"
    )
    public static let withdraw = NSLocalizedString(
        "Withdraw",
        comment: "Withdraw"
    )
    public static let withdrawTo = NSLocalizedString(
        "Withdraw to...",
        comment: "Withdraw to..."
    )
    public static let account = NSLocalizedString("Account", comment: "Account")
    public static let availableToWithdrawTitle = NSLocalizedString(
        "Available to Withdraw",
        comment: "Available to Withdraw"
    )

    public static let confirmationDisclaimer = NSLocalizedString(
        "Your final amount might change due to market activity. For your security, buy orders with a bank account are subject up to a 14 day holding period. You can Swap or Sell during this time. We will notify you once the funds are fully available.",
        comment: "Your final amount might change due to market activity. For your security, buy orders with a bank account are subject up to a 14 day holding period. You can Swap or Sell during this time. We will notify you once the funds are fully available."
    )
}

extension LocalizationConstants.Transaction.Transfer {
    public static let transferFrom = NSLocalizedString(
        "Transfer from...",
        comment: "Transfer from..."
    )
    public static let transferNow = NSLocalizedString(
        "Transfer Now",
        comment: "Transfer Now"
    )
    public static let transfer = NSLocalizedString("Transfer", comment: "Transfer")
}

extension LocalizationConstants.Transaction.Deposit {
    public static let linkedBanks = NSLocalizedString(
        "Linked Banks",
        comment: "Linked Banks"
    )
    public static let add = NSLocalizedString("Add", comment: "Add")

    public static let dailyLimit = NSLocalizedString("Daily Limit", comment: "Daily Limit")

    public static let deposit = NSLocalizedString("Deposit", comment: "Deposit")

    public static let depositNow = NSLocalizedString("Deposit Now", comment: "Deposit Now")
}

extension LocalizationConstants.Transaction.Send {
    public static let send = NSLocalizedString(
        "Send",
        comment: "Send"
    )
    public static let sendMax = NSLocalizedString(
        "Send Max",
        comment: "Send Max"
    )
    public static let from = NSLocalizedString(
        "From",
        comment: "From"
    )
    public static let to = NSLocalizedString(
        "To",
        comment: "To"
    )
    public static let networkFee = NSLocalizedString(
        "Network Fee",
        comment: "Network Fee"
    )
    public static let regular = NSLocalizedString(
        "Regular",
        comment: "Regular"
    )
    public static let priority = NSLocalizedString(
        "Priority",
        comment: "Priority"
    )
    public static let custom = NSLocalizedString(
        "Custom",
        comment: "Custom"
    )
    public static let min = NSLocalizedString(
        "Min",
        comment: "Abbreviation for minutes"
    )
    public static let minutes = NSLocalizedString(
        "Minutes",
        comment: "Minutes"
    )
}

extension LocalizationConstants.Transaction.TargetSource.Card {
    public static let internalSendOnly = NSLocalizedString("Internal Send Only", comment: "Internal Send Only")

    public static let description = NSLocalizedString(
        "At this time you can only transfer %@ from your %@ Trading Account to your %@ Private Key Wallets. Once %@ is in your Private Key Wallet you can transfer to external addresses.",
        comment: "At this time you can only transfer %@ from your %@ Trading Account to your %@ Private Key Wallets. Once %@ is in your Private Key Wallet you can transfer to external addresses."
    )
}

extension LocalizationConstants.Transaction.Send.AmountPresenter.LimitView {
    public static let useMin = NSLocalizedString(
        "The minimum send is %@",
        comment: "The minimum send is"
    )
    public static let useMax = NSLocalizedString(
        "You can send up to %@",
        comment: "You can send up to"
    )
}

extension LocalizationConstants.Transaction.Buy {

    public static let title = NSLocalizedString(
        "Buy",
        comment: "Buy screen title prefix"
    )
    public static let selectSourceTitle = NSLocalizedString(
        "Select a Payment Method",
        comment: "Title of screen to select a Payment Method to Buy"
    )
    public static let selectDestinationTitle = NSLocalizedString(
        "Select a Crypto Currency",
        comment: "Title of screen to select the Crypto Currency to Buy"
    )
    public static let confirmationDisclaimer = NSLocalizedString(
        "Your final amount might change due to market activity. Your funds will be available to Sell, Swap or Withdraw instantly.",
        comment: ""
    )
}

extension LocalizationConstants.Transaction.Sell {

    public static let title = NSLocalizedString(
        "Sell",
        comment: "Sell screen title prefix"
    )
    public static let headerTitlePrefix = NSLocalizedString(
        "From:",
        comment: "Sell screen header title prefix"
    )
    public static let headerSubtitlePrefix = NSLocalizedString(
        "To:",
        comment: "Sell screen header subtitle prefix"
    )
    public static let selectSourceTitle = NSLocalizedString(
        "Sell",
        comment: "Title of screen to select a wallet to Sell from"
    )
    public static let selectSourceSubtitle = NSLocalizedString(
        "Select a wallet to sell from.",
        comment: "Subtitle of screen to select a wallet to Sell from"
    )
    public static let selectDestinationTitle = NSLocalizedString(
        "Select a wallet to sell to.",
        comment: "Title of screen to select the Crypto Currency to Buy"
    )
}

extension LocalizationConstants.Transaction.Swap {
    public static let title = swap
    public static let swap = NSLocalizedString(
        "Swap",
        comment: "Swap"
    )
    public static let swapMax = NSLocalizedString(
        "Swap Max",
        comment: "Swap Max"
    )
    public static let confirmationDisclaimer = NSLocalizedString(
        "The amounts you send and receive may change slightly due to market activity. Once an order starts, we are unable to stop it.",
        comment: "Confirmation screen disclaimer."
    )
    public static let sourceAccountPicketSubtitle = NSLocalizedString(
        "Which wallet do you want to Swap from?",
        comment: "Swap Source Account Picket Header Subtitle"
    )
    public static let destinationAccountPicketSubtitle = NSLocalizedString(
        "Which crypto do you want to Swap for?",
        comment: "Swap Destination Account Picket Header Subtitle"
    )
    public static let swapNow = NSLocalizedString(
        "Swap Now",
        comment: "Swap Now"
    )
    public static let sendNow = NSLocalizedString(
        "Send Now",
        comment: "Send Now"
    )
    public static let buyNow = NSLocalizedString(
        "Buy Now",
        comment: "Buy Now"
    )
    public static let sellNow = NSLocalizedString(
        "Sell Now",
        comment: "Sell Now"
    )
    public static let sell = NSLocalizedString(
        "Sell %@",
        comment: "Sell %@"
    )
    public static let deposit = NSLocalizedString(
        "Confirm Transfer",
        comment: "Confirm Transfer"
    )
    public static let newSwapDisclaimer = NSLocalizedString(
        "Confirm the wallet you want to Swap from and choose the wallet you want to Receive into.",
        comment: "Confirm the wallet you want to Swap from and choose the wallet you want to Receive into."
    )
}

// MARK: - Interest Withdraw

extension LocalizationConstants.Transaction.InterestWithdraw {
    public static let confirmationDisclaimer = NSLocalizedString(
        "After confirming this withdrawal, you will not continue to earn rewards on the amount withdrawn. Your %@ will be available in your %@ within 2 days.",
        comment: "After confirming this withdrawal, you will not continue to earn rewards on the amount withdrawn. Your %@ will be available within 2 days."
    )
}

extension LocalizationConstants.Transaction.InterestWithdraw.Completion.Pending {
    public static let title = NSLocalizedString("Withdrawing %@", comment: "Withdrawing %@")
    public static let description = NSLocalizedString(
        "We're completing your withdraw now.",
        comment: "We're completing your withdraw now."
    )
}

extension LocalizationConstants.Transaction.InterestWithdraw.Completion.Success {
    public static let title = NSLocalizedString("%@ Withdrawn", comment: "%@ Withdrawn")
    public static let description = NSLocalizedString(
        "Your %@ has been withdrawn successfully.",
        comment: "Your %@ has been withdrawn successfully."
    )
    public static let action = NSLocalizedString("OK", comment: "OK")
}

extension LocalizationConstants.Transaction.InterestWithdraw.Completion.Failure {
    public static let title = NSLocalizedString(
        "Oops! Something Went Wrong.",
        comment: "Oops! Something Went Wrong."
    )
    public static let description = NSLocalizedString(
        "Don’t worry. Your funds are safe. Please try again or contact our Support Team for help.",
        comment: "Don’t worry. Your funds are safe. Please try again or contact our Support Team for help."
    )
}

// MARK: - Interest Transfer

extension LocalizationConstants.Transaction.Transfer.ToS {
    public static let prefix = NSLocalizedString("I have read and agree to the", comment: "I have read and agree to the")
    public static let termsOfService = NSLocalizedString("Terms of Service", comment: "Terms of Service")
    public static let privacyPolicy = NSLocalizedString("Privacy Policy", comment: "Privacy Policy")
}

extension LocalizationConstants.Transaction.Transfer {
    public static let termsOfService = NSLocalizedString("Terms of Service", comment: "Terms of Service")
    public static let privacyPolicy = NSLocalizedString("Privacy Policy", comment: "Privacy Policy")

    public static let termsOfServiceDisclaimer = NSLocalizedString(
        "I have read and agree to the Terms of Service & Privacy Policy.",
        comment: "I have read and agree to the Terms of Service & Privacy Policy."
    )

    public static let transferAgreement = NSLocalizedString(
        "By accepting this, you agree to transfer %@ from your %@ Wallet to your Rewards Account. An initial hold period of 7 days will be applied to your funds.",
        comment: "By accepting this, you agree to transfer %@ from your %@ Wallet to your Rewards Account. An initial hold period of 7 days will be applied to your funds."
    )
}

extension LocalizationConstants.Transaction.Transfer.Completion.Pending {
    public static let title = NSLocalizedString("Transferring %@", comment: "Transferring %@")
    public static let description = NSLocalizedString(
        "We're completing your transfer now.",
        comment: "We're completing your transfer now."
    )
}

extension LocalizationConstants.Transaction.Transfer.Completion.Success {
    public static let title = NSLocalizedString("%@ Transferred", comment: "%@ Transferred")
    public static let description = NSLocalizedString(
        "Your %@ has been transferred successfully.",
        comment: "Your %@ has been transferred successfully."
    )
    public static let action = NSLocalizedString("OK", comment: "OK")
}

extension LocalizationConstants.Transaction.Transfer.Completion.Failure {
    public static let title = NSLocalizedString(
        "Oops! Something Went Wrong.",
        comment: "Oops! Something Went Wrong."
    )
    public static let description = NSLocalizedString(
        "Don’t worry. Your funds are safe. Please try again or contact our Support Team for help.",
        comment: "Don’t worry. Your funds are safe. Please try again or contact our Support Team for help."
    )
}

// MARK: - Withdraw Pending

extension LocalizationConstants.Transaction.Withdraw.Completion.Pending {
    public static let title = NSLocalizedString("Withdrawing %@", comment: "Withdrawing %@")
    public static let description = NSLocalizedString(
        "We're completing your withdraw now.",
        comment: "We're completing your withdraw now."
    )
}

extension LocalizationConstants.Transaction.Withdraw.Completion.Success {
    public static let title = NSLocalizedString("%@ Withdrawal Started", comment: "%@ Withdrawal Started")
    public static let description = NSLocalizedString(
        "We are sending the cash now. Expect the cash to hit your bank on %@. Check the status of your Withdrawal at anytime from your Activity screen.",
        comment: "We are sending the cash now. Expect the cash to hit your bank on %@. Check the status of your Withdrawal at anytime from your Activity screen."
    )
}

extension LocalizationConstants.Transaction.Withdraw.Completion.Failure {
    public static let title = NSLocalizedString(
        "Oops! Something Went Wrong.",
        comment: "Oops! Something Went Wrong."
    )
    public static let description = NSLocalizedString(
        "Don’t worry. Your funds are safe. Please try again or contact our Support Team for help.",
        comment: "Don’t worry. Your funds are safe. Please try again or contact our Support Team for help."
    )
}

// MARK: - Deposit Pending

extension LocalizationConstants.Transaction.Deposit.Completion.Pending {
    public static let title = NSLocalizedString("Depositing %@", comment: "Depositing %@")
    public static let description = NSLocalizedString(
        "We're completing your deposit now.",
        comment: "We're completing your deposit now."
    )
}

extension LocalizationConstants.Transaction.Deposit.Completion.Success {
    public static let title = NSLocalizedString("%@ Deposited", comment: "%@ Deposited")
    public static let description = NSLocalizedString(
        "While we wait for your bank to send the cash, here’s early access to %@ in your %@ Cash Account so you can buy crypto right now. Your funds will be available to withdraw once the bank transfer is complete on %@",
        comment: "While we wait for your bank to send the cash, here’s early access to $@ in your %@ Cash Account so you can buy crypto right now. Your funds will be available to withdraw once the bank transfer is complete on %@"
    )
}

extension LocalizationConstants.Transaction.Deposit.Completion.Failure {
    public static let title = NSLocalizedString(
        "Oops! Something Went Wrong.",
        comment: "Oops! Something Went Wrong."
    )
    public static let description = NSLocalizedString(
        "Don’t worry. Your funds are safe. Please try again or contact our Support Team for help.",
        comment: "Don’t worry. Your funds are safe. Please try again or contact our Support Team for help."
    )
}

// MARK: - Send Pending

extension LocalizationConstants.Transaction.Send.Completion.Pending {
    public static let title = NSLocalizedString(
        "Sending %@",
        comment: "Sending %@"
    )
    public static let description = NSLocalizedString(
        "We're sending your transaction now.",
        comment: "We're sending your transaction now."
    )
}

extension LocalizationConstants.Transaction.Send.Completion.Success {
    public static let title = NSLocalizedString(
        "%@ Sent",
        comment: "Send Complete"
    )
    public static let description = NSLocalizedString(
        "Your %@ has been successfully sent.",
        comment: "Your %@ has been successfully sent."
    )
    public static let action = NSLocalizedString(
        "OK",
        comment: "OK"
    )
}

extension LocalizationConstants.Transaction.Send.Completion.Failure {
    public static let title = NSLocalizedString(
        "Oops! Something Went Wrong.",
        comment: "Oops! Something Went Wrong."
    )
    public static let description = NSLocalizedString(
        "Don’t worry. Your crypto is safe. Please try again or contact our Support Team for help.",
        comment: "Don’t worry. Your crypto is safe. Please try again or contact our Support Team for help."
    )
    public static let action = NSLocalizedString(
        "OK",
        comment: "OK"
    )

    public static let insufficientFundsForFees = NSLocalizedString(
        "Not enough %@ in your wallet to send with current network fees.",
        comment: ""
    )

    public static let underMinLimit = NSLocalizedString(
        "Minimum send of %@ required.",
        comment: ""
    )
}

// MARK: - Sign

extension LocalizationConstants.Transaction.Sign {
    public static let dappRequestWarning = NSLocalizedString(
        "%@ is requesting an action, which could take money from your wallet. Make sure you trust this site.",
        comment: "Dapp request warning."
    )
}

extension LocalizationConstants.Transaction.Sign.Completion.Pending {
    public static let title = NSLocalizedString(
        "Signing",
        comment: "Signing"
    )
    public static let description = NSLocalizedString(
        "We're signing your transaction now.",
        comment: "We're signing your transaction now."
    )
}

extension LocalizationConstants.Transaction.Sign.Completion.Success {
    public static let title = NSLocalizedString(
        "Signed",
        comment: "Signed"
    )
    public static let description = NSLocalizedString(
        "The message has been successfully signed. Go back to the dApp.",
        comment: "The message has been successfully signed. Go back to the dApp."
    )
    public static let action = NSLocalizedString(
        "OK",
        comment: "OK"
    )
}

extension LocalizationConstants.Transaction.Sign.Completion.Failure {
    public static let title = NSLocalizedString(
        "Oops! Something Went Wrong.",
        comment: "Oops! Something Went Wrong."
    )
    public static let description = NSLocalizedString(
        "Don’t worry. Your crypto is safe. Please try again or contact our Support Team for help.",
        comment: "Don’t worry. Your crypto is safe. Please try again or contact our Support Team for help."
    )
    public static let action = NSLocalizedString(
        "OK",
        comment: "OK"
    )
}

// MARK: - Swap Pending

extension LocalizationConstants.Transaction.Swap.Completion.Pending {
    public static let title = NSLocalizedString(
        "Swapping %@ for %@",
        comment: "Swapping %@ for %@"
    )
    public static let description = NSLocalizedString(
        "We're completing your swap now.",
        comment: "We're completing your swap now."
    )
}

extension LocalizationConstants.Transaction.Swap.Completion.Success {
    public static let title = NSLocalizedString(
        "Swap Complete",
        comment: "Swap Complete"
    )
    public static let description = NSLocalizedString(
        "Your %@ is now available in your Wallet.",
        comment: "Your %@ is now available in your Wallet."
    )
    public static let action = NSLocalizedString(
        "OK",
        comment: "OK"
    )
}

extension LocalizationConstants.Transaction.Swap.Completion.Failure {
    public static let title = NSLocalizedString(
        "Oops! Something Went Wrong.",
        comment: "Oops! Something Went Wrong."
    )
    public static let description = NSLocalizedString(
        "Don’t worry. Your crypto is safe. Please try again or contact our Support Team for help.",
        comment: "Don’t worry. Your crypto is safe. Please try again or contact our Support Team for help."
    )
    public static let action = NSLocalizedString(
        "OK",
        comment: "OK"
    )

    public static let insufficientFundsForFees = NSLocalizedString(
        "Not enough %@ in your wallet to swap with current network fees.",
        comment: ""
    )

    public static let underMinLimit = NSLocalizedString(
        "Minimum swap of %@ required.",
        comment: ""
    )
}

// MARK: - Buy

extension LocalizationConstants.Transaction.Buy.Completion.Success {
    public static let title = NSLocalizedString(
        "Buy Complete",
        comment: "Buy Complete"
    )
    public static let description = NSLocalizedString(
        "Your %@ is now available in your Wallet.",
        comment: "Your %@ is now available in your Wallet."
    )
    public static let action = NSLocalizedString(
        "OK",
        comment: "OK"
    )
    public static let upgrade = NSLocalizedString(
        "Want to buy more?",
        comment: "Prompt to upgrade to a higher KYC Tier"
    )
}

extension LocalizationConstants.Transaction.Buy.Completion.InProgress {
    public static let title = NSLocalizedString(
        "Buying %@ with %@",
        comment: "Buying [target crypto] with [source fiat]"
    )
    public static let description = NSLocalizedString(
        "We're completing your buy order now.",
        comment: "We're completing your buy order now."
    )
    public static let upgrade = NSLocalizedString(
        "Want to buy more?",
        comment: "Prompt to upgrade to a higher KYC Tier"
    )
}

extension LocalizationConstants.Transaction.Buy.Completion.Pending {
    public static let title = NSLocalizedString(
        "We're still processing your order.",
        comment: "Order pending title"
    )
    public static let description = NSLocalizedString(
        "This may take some time. We'll let you know when it's done.",
        comment: "Order peding message."
    )
    public static let upgrade = NSLocalizedString(
        "Want to buy more?",
        comment: "Prompt to upgrade to a higher KYC Tier"
    )
}

extension LocalizationConstants.Transaction.Buy.Completion.Failure {
    public static let title = NSLocalizedString(
        "Oops! Something Went Wrong.",
        comment: "Oops! Something Went Wrong."
    )

    public static let description = NSLocalizedString(
        "Don’t worry. Your crypto is safe. Please try again or contact our Support Team for help.",
        comment: "Don’t worry. Your crypto is safe. Please try again or contact our Support Team for help."
    )

    public static let action = NSLocalizedString(
        "OK",
        comment: "OK"
    )

    public static let insufficientFundsForFees = NSLocalizedString(
        "Not enough %@ in your wallet to buy with current network fees.",
        comment: ""
    )

    public static let underMinLimit = NSLocalizedString(
        "Minimum buy is %@.",
        comment: ""
    )
}

// MARK: - Sell

extension LocalizationConstants.Transaction.Sell.Completion.Success {
    public static let title = NSLocalizedString(
        "Sell Complete",
        comment: "Sell Complete"
    )
    public static let description = NSLocalizedString(
        "Your %@ is now available in your Wallet.",
        comment: "Your %@ is now available in your Wallet."
    )
    public static let action = NSLocalizedString(
        "OK",
        comment: "OK"
    )
}

extension LocalizationConstants.Transaction.Sell.Completion.Pending {
    public static let title = NSLocalizedString(
        "Selling %@ for %@",
        comment: "Selling %@ for %@"
    )
    public static let description = NSLocalizedString(
        "We're completing your sell now.",
        comment: "We're completing your sell now."
    )
}

extension LocalizationConstants.Transaction.Sell.Completion.Failure {
    public static let title = NSLocalizedString(
        "Oops! Something Went Wrong.",
        comment: "Oops! Something Went Wrong."
    )

    public static let description = NSLocalizedString(
        "Don’t worry. Your crypto is safe. Please try again or contact our Support Team for help.",
        comment: "Don’t worry. Your crypto is safe. Please try again or contact our Support Team for help."
    )

    public static let action = NSLocalizedString(
        "OK",
        comment: "OK"
    )

    public static let insufficientFundsForFees = NSLocalizedString(
        "Not enough %@ in your wallet to sell with current network fees.",
        comment: ""
    )

    public static let underMinLimit = NSLocalizedString(
        "Minimum sell of %@ required.",
        comment: ""
    )
}

// MARK: - Confirmation

extension LocalizationConstants.Transaction.Confirmation.Error {
    public static let title = NSLocalizedString("Error", comment: "Error")
    public static let insufficientFunds = NSLocalizedString(
        "You have insufficient funds in this account to process this transaction",
        comment: ""
    )
    public static let insufficientGas = NSLocalizedString(
        "You do not have enough ETH to process this transaction.",
        comment: ""
    )
    public static let optionInvalid = NSLocalizedString(
        "Please ensure you've agreed to our Terms.",
        comment: ""
    )
    public static let invoiceExpired = NSLocalizedString(
        "BitPay Invoice Expired",
        comment: ""
    )
    public static let underMinLimit = NSLocalizedString(
        "%@ Min",
        comment: ""
    )
    public static let underMinBitcoinFee = NSLocalizedString(
        "Minimum 1 sat/byte required",
        comment: ""
    )
    public static let transactionInFlight = NSLocalizedString(
        "A transaction is already in progress",
        comment: ""
    )
    public static let pendingOrderLimitReached = NSLocalizedString(
        "You can start this transaction once one of the pending orders finish.",
        comment: "User has reached the maximum limit of unfulfilled pending orders and cannot create new orders at this time."
    )
    public static let generic = NSLocalizedString(
        "An unexpected error has occurred. Please try again.",
        comment: ""
    )
    public static let overMaximumLimit = NSLocalizedString(
        "Maximum limit exceeded",
        comment: ""
    )
}

extension LocalizationConstants.Transaction.Confirmation {
    public static let buy = NSLocalizedString(
        "Buy",
        comment: "Buy"
    )
    public static let paymentMethod = NSLocalizedString(
        "Payment Method",
        comment: "Payment Method"
    )
    public static let price = NSLocalizedString(
        "%@ Price",
        comment: "%@ Price"
    )
    public static let purchase = NSLocalizedString(
        "Purchase",
        comment: "Total - Blockchain.com Fee"
    )
    public static let total = NSLocalizedString(
        "Total",
        comment: "Total"
    )
    public static let to = NSLocalizedString(
        "To",
        comment: "To"
    )
    public static let from = NSLocalizedString(
        "From",
        comment: "From"
    )
    public static let transactionFee = NSLocalizedString(
        "Transaction Fee",
        comment: "Network Fee"
    )
    public static let blockchainFee = NSLocalizedString(
        "Blockchain.com Fee",
        comment: "Blockchain.com Fee"
    )
    public static let networkFee = NSLocalizedString(
        "%@ Network Fee",
        comment: "%@ Network Fee"
    )
    public static let exchangeRate = NSLocalizedString(
        "Exchange Rate",
        comment: "Exchange Rate"
    )
    public static let fundsArrivalDate = NSLocalizedString(
        "Funds Will Arrive",
        comment: "Funds Will Arrive"
    )
    public static let description = NSLocalizedString(
        "Description",
        comment: "Description"
    )
    public static let memo = NSLocalizedString(
        "Memo",
        comment: "Memo"
    )
    public static let confirm = NSLocalizedString(
        "Confirm",
        comment: "Confirm"
    )
    public static let signatureRequest = NSLocalizedString(
        "Signature Request",
        comment: "Signature Request title"
    )
    public static let sendRequest = NSLocalizedString(
        "Send",
        comment: "Send Request title"
    )
    public static let cancel = NSLocalizedString(
        "Cancel",
        comment: "Cancel"
    )

    public static func transactionFee(feeType: String) -> String {
        let format = NSLocalizedString(
            "Fee - %@",
            comment: "Fee"
        )
        return String(format: format, feeType)
    }

    public static let remainingTime = NSLocalizedString(
        "Remaining Time",
        comment: "Remaining Time"
    )

    public static let app = NSLocalizedString(
        "App",
        comment: "App"
    )
    public static let message = NSLocalizedString(
        "Message from %@",
        comment: "Message from %@"
    )
    public static let rawTransaction = NSLocalizedString(
        "Raw transaction from %@",
        comment: "Raw transaction from %@"
    )
    public static let network = NSLocalizedString(
        "Network",
        comment: "Network"
    )
}

extension LocalizationConstants.Transaction.Error {
    public static let title = NSLocalizedString("Error", comment: "Error")
    public static let insufficientFunds = NSLocalizedString(
        "You have insufficient funds in this account to process this transaction",
        comment: ""
    )
    public static let insufficientGas = NSLocalizedString(
        "You do not have enough ETH to process this transaction.",
        comment: ""
    )
    public static let addressIsContract = NSLocalizedString(
        "Address is not a user address",
        comment: ""
    )
    public static let optionInvalid = NSLocalizedString(
        "Please ensure you've agreed to our Terms.",
        comment: ""
    )
    public static let invoiceExpired = NSLocalizedString(
        "BitPay Invoice Expired",
        comment: ""
    )
    public static let underMinLimitGeneric = NSLocalizedString(
        "Minimum amount required.",
        comment: ""
    )
    public static let underMinBitcoinFee = NSLocalizedString(
        "Minimum 1 sat/byte required",
        comment: ""
    )
    public static let transactionInFlight = NSLocalizedString(
        "A transaction is already in progress",
        comment: ""
    )
    public static let maximumPendingOrderLimitReached = NSLocalizedString(
        "Right now, we only allow up to %@ buys pending at a time.",
        comment: "User has reached the maximum limit of unfulfilled pending orders and cannot create new orders at this time."
    )
    public static let pendingOrderLimitReached = NSLocalizedString(
        "You can start this transaction once one of the pending orders finish.",
        comment: "User has reached the maximum limit of unfulfilled pending orders and cannot create new orders at this time."
    )
    public static let generic = NSLocalizedString(
        "An unexpected error has occurred. Please try again.",
        comment: ""
    )
    public static let errorCode = NSLocalizedString(
        "Error Code: %@",
        comment: ""
    )
    public static let overMaximumLimit = NSLocalizedString(
        "Maximum limit exceeded",
        comment: ""
    )
    public static let invalidPassword = NSLocalizedString(
        "Password is incorrect.",
        comment: ""
    )
    public static let invalidAddress = NSLocalizedString(
        "Not a valid address.",
        comment: ""
    )
    public static let insufficientFundsForFees = NSLocalizedString(
        "Not enough %@ in your wallet to send with current network fees.",
        comment: ""
    )

    // MARK: - Error Recovery Messages

    public static let insufficientFundsRecoveryHint = NSLocalizedString(
        "Not Enough %@",
        comment: "Error CTA - insufficient funds to perform transaction"
    )
    public static let insufficientFundsRecoveryTitle = NSLocalizedString(
        "Not Enough %@",
        comment: "Error recovery title - insufficient funds to perform transaction"
    )
    public static let insufficientFundsRecoveryTitle_swap = NSLocalizedString(
        "%@ Maximum",
        comment: "Error recovery title - insufficient funds to perform transaction - swap"
    )
    public static let insufficientFundsRecoveryMessage_buy = NSLocalizedString(
        "The maximum amount of %@ you can buy with your %@ Account is **%@**.",
        comment: "Error recovery message - insufficient funds to perform 'buy' transaction"
    )
    public static let insufficientFundsRecoveryMessage_sell = NSLocalizedString(
        "The maximum amount of %@ you can sell from this account is **%@**.",
        comment: "Error recovery message - insufficient funds to perform 'sell' transaction"
    )
    public static let insufficientFundsRecoveryMessage_swap = NSLocalizedString(
        "The maximum amount of %@ you can swap for %@ is **%@**.",
        comment: "Error recovery message - insufficient funds to perform 'swap' transaction"
    )
    public static let insufficientFundsRecoveryMessage_send = NSLocalizedString(
        "The maximum amount of %@ you can send is **%@**.",
        comment: "Error recovery message - insufficient funds to perform 'send' transaction"
    )
    public static let insufficientFundsRecoveryMessage_withdraw = NSLocalizedString(
        "The maximum amount of %@ you can withdraw from this account is **%@**.",
        comment: "Error recovery message - insufficient funds to perform 'swap' transaction"
    )
    public static let insuffientFundsToPayForFeesMessage = NSLocalizedString(
        "You don't have enough %@ to pay for fees. The expected fee for this transaction is **%@**. Please note that **we don't set nor collect fees for transactions from Private Key Wallets**. Those fees go directly to the blockchain's node validators and are algoritmically set by the %@ network.",
        comment: "Error recovery message - insufficient funds to pay for fees for transaction"
    )
    public static let belowFeeRecoveryHint = NSLocalizedString(
        "%@ Minimum",
        comment: "Error recovery hint - balance below fees required for transaction"
    )
    public static let belowFeeRecoveryTitle = NSLocalizedString(
        "%@ Minimum",
        comment: "Error recovery title - balance below fees required for transaction"
    )
    public static let belowFeeRecoveryMessage = NSLocalizedString(
        "To execture this transaction the expected fee is %@ but your balance is only %@.",
        comment: "Error recovery message - balance below fees required for transaction"
    )
    public static let belowMinimumLimitRecoveryHint = NSLocalizedString(
        "%@ Minimum",
        comment: "Error CTA - input below minimum amount valid for transaction"
    )
    public static let belowMinimumLimitRecoveryTitle = NSLocalizedString(
        "%@ Minimum",
        comment: "Error recovery title - input below minimum amount valid for transaction"
    )
    public static let belowMinimumLimitRecoveryMessage_buy = NSLocalizedString(
        "To offset fees and market volatility, the minimum amount for any buy is **%@**.",
        comment: "Error recovery message - input below minimum amount valid for 'buy' transaction"
    )
    public static let belowMinimumLimitRecoveryMessage_sell = NSLocalizedString(
        "The minimum amount for you can sell is **%@**.",
        comment: "Error recovery message - input below minimum amount valid for 'sell' transaction"
    )
    public static let belowMinimumLimitRecoveryMessage_swap = NSLocalizedString(
        "To avoid uncesssary fees and network slipage, the minimum amount for this pair is **%@**.",
        comment: "Error recovery message - input below minimum amount valid for 'swap' transaction"
    )
    public static let belowMinimumLimitRecoveryMessage_send = NSLocalizedString(
        "The minimum amount for you can send is **%@**.",
        comment: "Error recovery message - input below minimum amount valid for 'send' transaction"
    )
    public static let belowMinimumLimitRecoveryMessage_deposit = NSLocalizedString(
        "The minimum amount for you can deposit is **%@**.",
        comment: "Error recovery message - input below minimum amount valid for 'deposit' transaction"
    )
    public static let belowMinimumLimitRecoveryMessage_withdraw = NSLocalizedString(
        "To offset fees, the minimum amount for any withdrawal is **%@**.",
        comment: "Error recovery message - input below minimum amount valid for 'withdraw' transaction"
    )
    public static let overMaximumSourceLimitRecoveryHint = NSLocalizedString(
        "%@ Maximum",
        comment: "Error CTA - input over maximum limit for source account"
    )
    public static let overMaximumSourceLimitRecoveryTitle = NSLocalizedString(
        "%@ Maximum",
        comment: "Error recovery title - input over maximum limit for source account"
    )
    public static let overMaximumSourceLimitRecoveryMessage_buy_funds = NSLocalizedString(
        "The maximum amount of %@ you can buy with your %@ Account is **%@**.",
        comment: "Error recovery message - insufficient funds to perform 'buy' transaction"
    )
    public static let overMaximumSourceLimitRecoveryMessage_buy = NSLocalizedString(
        "Looks like your **%@** only allows buys up to **%@ at at time**. To buy **%@**, split your buy into multiple transactions.",
        comment: "Error recovery message - input over maximum limit for source account - buy"
    )
    public static let overMaximumSourceLimitRecoveryMessage_sell = NSLocalizedString(
        "The maximum amount of %@ you can sell from this account is **%@**.",
        comment: "Error recovery message - input over maximum limit for source account - sell"
    )
    public static let overMaximumSourceLimitRecoveryMessage_swap = NSLocalizedString(
        "The maximum amount of %@ you can swap for %@ is **%@**.",
        comment: "Error recovery message - input over maximum limit for source account - swap"
    )
    public static let overMaximumSourceLimitRecoveryMessage_deposit = NSLocalizedString(
        "Looks like your **%@** only allows deposits up to **%@ at at time**. To deposit **%@**, split your deposit into multiple transactions.",
        comment: "Error recovery message - input over maximum limit for source account - deposit"
    )
    public static let overMaximumSourceLimitRecoveryMessage_withdraw = NSLocalizedString(
        "The maximum amount of %@ you can withdraw from this account is **%@**.",
        comment: "Error recovery message - input over maximum limit for source account - withdraw"
    )
    public static let overMaximumSourceLimitRecoveryMessage_send = NSLocalizedString(
        "The max you can send from this wallet is **%@**. Buy **%@** now to send this amount.",
        comment: "Error recovery message - input over maximum limit for source account - send"
    )
    public static let belowFeesRecoveryCalloutTitle_send = NSLocalizedString(
        "Get More %@",
        comment: "Error recovery callout - title for callout asking the user to buy more crypto to perform a 'send' action."
    )
    public static let belowFeesRecoveryCalloutMessage_send = NSLocalizedString(
        "Buy enough %@ to pay for fees plus any you want to send.",
        comment: "Error recovery callout - message for callout asking the user to buy more crypto to perform a 'send' action."
    )
    public static let belowFeesRecoveryCalloutCTA_send = NSLocalizedString(
        "BUY",
        comment: "Error recovery callout - small CTA for callout asking the user to buy more crypto to perform a 'send' action."
    )
    public static let overMaximumSourceLimitRecoveryCalloutTitle_send = NSLocalizedString(
        "Get More %@",
        comment: "Error recovery callout - title for callout asking the user to buy more crypto to perform a 'send' action."
    )
    public static let overMaximumSourceLimitRecoveryCalloutMessage_send = NSLocalizedString(
        "Buy %@",
        comment: "Error recovery callout - message for callout asking the user to buy more crypto to perform a 'send' action."
    )
    public static let overMaximumSourceLimitRecoveryCalloutCTA_send = NSLocalizedString(
        "BUY",
        comment: "Error recovery callout - small CTA for callout asking the user to buy more crypto to perform a 'send' action."
    )
    public static let overMaximumPersonalLimitRecoveryHint = NSLocalizedString(
        "Over your limit",
        comment: "Error recovery message - input over the user's personal maximum limit"
    )
    public static let overMaximumPersonalLimitRecoveryTitle = NSLocalizedString(
        "Over your limit",
        comment: "Error recovery message - input over the user's personal maximum limit"
    )
    public static let overMaximumPersonalLimitRecoveryMessage_buy_single = NSLocalizedString(
        "You can buy up to **%@** per transaction. Upgrade to Gold & buy larger amounts with your bank or card.",
        comment: "Error recovery message - input over the user's personal maximum limit - buy"
    )
    public static let overMaximumPersonalLimitRecoveryMessage_buy_gold = NSLocalizedString(
        "You can only buy **%@**. You have **%@ remaining**. Upgrade to Gold to buy more.",
        comment: "Error recovery message - input over the user's personal maximum limit - buy"
    )
    public static let overMaximumPersonalLimitRecoveryMessage_buy_other = NSLocalizedString(
        "You can only buy **%@**. You have **%@ remaining**.",
        comment: "Error recovery message - input over the user's personal maximum limit - buy"
    )
    public static let overMaximumPersonalLimitRecoveryMessage_sell_single = NSLocalizedString(
        "You can sell up to **%@** for this transaction.",
        comment: "Error recovery message - input over the user's personal maximum limit - sell"
    )
    public static let overMaximumPersonalLimitRecoveryMessage_sell_gold = NSLocalizedString(
        "You can only sell **%@**. You have **%@ remaining**.",
        comment: "Error recovery message - input over the user's personal maximum limit - sell"
    )
    public static let overMaximumPersonalLimitRecoveryMessage_sell_other = NSLocalizedString(
        "You can only sell **%@**. You have **%@ remaining**.",
        comment: "Error recovery message - input over the user's personal maximum limit - sell"
    )
    public static let overMaximumPersonalLimitRecoveryMessage_swap_single = NSLocalizedString(
        "You can swap up to **%@** for this transaction.",
        comment: "Error recovery message - input over the user's personal maximum limit - swap"
    )
    public static let overMaximumPersonalLimitRecoveryMessage_swap_gold = NSLocalizedString(
        "You can only swap **%@**. You have **%@ remaining**.",
        comment: "Error recovery message - input over the user's personal maximum limit - swap"
    )
    public static let overMaximumPersonalLimitRecoveryMessage_swap_other = NSLocalizedString(
        "You can only swap **%@**. You have **%@ remaining**.",
        comment: "Error recovery message - input over the user's personal maximum limit - swap"
    )
    public static let overMaximumPersonalLimitRecoveryMessage_send_single = NSLocalizedString(
        "You can send up to **%@** for this transaction.",
        comment: "Error recovery message - input over the user's personal maximum limit - send"
    )
    public static let overMaximumPersonalLimitRecoveryMessage_send_gold = NSLocalizedString(
        "You can only send **%@**. You have **%@ remaining**.",
        comment: "Error recovery message - input over the user's personal maximum limit - send"
    )
    public static let overMaximumPersonalLimitRecoveryMessage_send_other = NSLocalizedString(
        "You can only send **%@**. You have **%@ remaining**.",
        comment: "Error recovery message - input over the user's personal maximum limit - send"
    )
    public static let overMaximumPersonalLimitRecoveryMessage_withdraw = NSLocalizedString(
        "Withdrawing from Trade Accounts cannot exceed **%@**. You have **%@ remaining**.",
        comment: "Error recovery message - input over the user's personal maximum limit - withdraw"
    )
    public static let overMaximumPersonalLimitRecoveryCalloutTitle_buy = NSLocalizedString(
        "Buy More Crypto",
        comment: "Error recovery callout - title for callout asking the user to upgrade their KYC info - buy"
    )
    public static let overMaximumPersonalLimitRecoveryCalloutTitle_swap = NSLocalizedString(
        "Swap More Crypto",
        comment: "Error recovery callout - title for callout asking the user to upgrade their KYC info - swap"
    )
    public static let overMaximumPersonalLimitRecoveryCalloutTitle_send = NSLocalizedString(
        "Get Unlimited Sends",
        comment: "Error recovery callout - title for callout asking the user to upgrade their KYC info - send"
    )
    public static let overMaximumPersonalLimitRecoveryCalloutTitle_other = NSLocalizedString(
        "Get higher limits",
        comment: "Error recovery callout - title for callout asking the user to upgrade their KYC info - other"
    )
    public static let overMaximumPersonalLimitRecoveryCalloutMessage = NSLocalizedString(
        "Upgrade Your Wallet",
        comment: "Error recovery callout - message for callout asking the user to upgrade their KYC info"
    )
    public static let overMaximumPersonalLimitRecoveryCalloutCTA = NSLocalizedString(
        "GO",
        comment: "Error recovery callout - small CTA for callout asking the user to upgrade their KYC info"
    )

    public static let overMaximumSourceLimitRecoveryValueTimeFrameDay = NSLocalizedString(
        "%@ a day",
        comment: "E.g. $10.00 a month"
    )

    public static let overMaximumSourceLimitRecoveryValueTimeFrameMonth = NSLocalizedString(
        "%@ a month",
        comment: "E.g. $10.00 a month"
    )

    public static let overMaximumSourceLimitRecoveryValueTimeFrameYear = NSLocalizedString(
        "%@ a year",
        comment: "E.g. $10.00 a year"
    )

    // MARK: Unchecked

    public static let insufficientGasShort = NSLocalizedString(
        "Insufficient gas",
        comment: ""
    )
    public static let addressIsContractShort = NSLocalizedString(
        "Invalid address",
        comment: ""
    )
    public static let optionInvalidShort = NSLocalizedString(
        "Review T&Cs",
        comment: ""
    )
    public static let invoiceExpiredShort = NSLocalizedString(
        "Invoice expired",
        comment: ""
    )
    public static let underMinBitcoinFeeShort = NSLocalizedString(
        "Fee too low",
        comment: ""
    )
    public static let transactionInFlightShort = NSLocalizedString(
        "Transaction in progress",
        comment: ""
    )
    public static let pendingOrdersLimitReachedShort = NSLocalizedString(
        "Too many active orders",
        comment: ""
    )
    public static let unknownErrorShort = NSLocalizedString(
        "Unexpected error",
        comment: ""
    )
    public static let fatalErrorShort = NSLocalizedString(
        "Fatal error",
        comment: ""
    )
    public static let nextworkErrorShort = NSLocalizedString(
        "Network error",
        comment: ""
    )
    public static let invalidPasswordShort = NSLocalizedString(
        "Incorrect password",
        comment: ""
    )
    public static let invalidAddressShort = NSLocalizedString(
        "Invalid address",
        comment: ""
    )
    public static let insufficientFundsForFeesShort = NSLocalizedString(
        "Not enough funds",
        comment: ""
    )

    // MARK: - Transaction Flow Pending Error Descriptions

    public static let unknownError = NSLocalizedString(
        "Oops! Something went wrong. Please try again.",
        comment: "Oops! Something went wrong. Please try again."
    )

    public static let tooManyTransaction = NSLocalizedString(
        "You have too many pending %@ transactions. Once those complete you can create a new one.",
        comment: "You have too many pending %@ transactions. Once those complete you can create a new one."
    )

    public static let orderNotCancellable = NSLocalizedString(
        "Oops! This %@ order is not cancellable.",
        comment: "Oops! This %@ order is not cancellable."
    )

    public static let pendingWithdraw = NSLocalizedString(
        "Oops! You’ve already got an existing pending withdrawal, please try again once that completes.",
        comment: "Oops! You’ve already got an existing pending withdrawal, please try again once that completes."
    )

    public static let withdrawBalanceLocked = NSLocalizedString(
        "Oops! For security reasons, your balance is currently locked, please try again later.",
        comment: "Oops! For security reasons, your balance is currently locked, please try again later."
    )

    public static let tradingInsufficientFunds = NSLocalizedString(
        "Oops! You don’t have enough funds to Withdraw",
        comment: "Oops! You don’t have enough funds to Withdraw"
    )

    public static let internalServiceError = NSLocalizedString(
        "Oops! This service is currently unavailable, please try again later.",
        comment: "Oops! This service is currently unavailable, please try again later."
    )

    public static let tradingAlbertError = NSLocalizedString(
        "Oops! Something Went Wrong. Please try again.",
        comment: "Oops! Something Went Wrong. Please try again."
    )

    public static let tradingServiceDisabled = NSLocalizedString(
        "This service will be back soon. We’re updating and fixing some bugs right now.",
        comment: "This service will be back soon. We’re updating and fixing some bugs right now."
    )

    public static let tradingInsufficientBalance = NSLocalizedString(
        "Oops! You don’t have enough balance to %@.",
        comment: "Oops! You don’t have enough balance to %@."
    )

    public static let tradingBelowMin = NSLocalizedString(
        "Oops! The amount you selected is below the minimum %@ limit.",
        comment: "Oops! The amount you selected is below the minimum %@ limit."
    )

    public static let tradingAboveMax = NSLocalizedString(
        "Oops! The amount you selected is above the maximum %@ limit.",
        comment: "Oops! The amount you selected is above the maximum %@ limit."
    )

    public static let tradingDailyExceeded = NSLocalizedString(
        "Oops! You’ve exceeded your daily %@ limit",
        comment: "Oops! You’ve exceeded your daily %@ limit"
    )

    public static let tradingWeeklyExceeded = NSLocalizedString(
        "Oops! You’ve exceeded your weekly %@ limit",
        comment: "Oops! You’ve exceeded your weekly %@ limit"
    )

    public static let tradingYearlyExceeded = NSLocalizedString(
        "Oops! You’ve exceeded your yearly %@ limit",
        comment: "Oops! You’ve exceeded your yearly %@ limit"
    )

    public static let tradingInvalidAddress = NSLocalizedString(
        "Oops! Looks like that address is invalid, please try again.",
        comment: "Oops! Looks like that address is invalid, please try again."
    )

    public static let tradingInvalidCurrency = NSLocalizedString(
        "Oops! Looks like that cryptocurrency is invalid, please try again.",
        comment: "Oops! Looks like that cryptocurrency is invalid, please try again."
    )

    public static let tradingInvalidFiat = NSLocalizedString(
        "Oops! Looks like that fiat is invalid, please try again.",
        comment: "Oops! Looks like that fiat is invalid, please try again."
    )

    public static let tradingDirectionDisabled = NSLocalizedString(
        "Oops! That service isn’t available at the moment, please try again later.",
        comment: "Oops! That service isn’t available at the moment, please try again later."
    )

    public static let tradingQuoteInvalidOrExpired = NSLocalizedString(
        "Oops! The amount we quoted you is no longer valid, please try again.",
        comment: "Oops! The amount we quoted you is no longer valid, please try again."
    )

    public static let executingTransactionError = NSLocalizedString(
        "Oops! Something went wrong while executing the %@ on-chain transaction.",
        comment: "Oops! Something went wrong while executing the %@ on-chain transaction."
    )

    public static let tradingIneligibleForSwap = NSLocalizedString(
        "Oops! This service isn’t currently available. Please contact support.",
        comment: "Oops! This service isn’t currently available. Please contact support."
    )

    public static let tradingInvalidDestinationAmount = NSLocalizedString(
        "Oops! Looks like that isn’t a valid amount, please try again.",
        comment: "Oops! Looks like that isn’t a valid amount, please try again."
    )

    public static let pendingTransactionLimit = NSLocalizedString(
        "Too Many Buys Pending",
        comment: "Pending Transaction Limit Title"
    )
}

extension LocalizationConstants.Transaction {
    public static let ok = NSLocalizedString("OK", comment: "OK")
}

extension LocalizationConstants.Transaction.TradingCurrency {

    public static let screenTitle = NSLocalizedString(
        "Select a Trading Currency.",
        comment: "Trading Currency Selection Screen: Title"
    )

    private static let screenSubtitleFormat = NSLocalizedString(
        "Right now, %@ is not supported for buying crypto. You can add a bank account or card from the list of available currencies below.",
        comment: "Trading Currency Selection Screen: Subtitle"
    )

    public static func screenSubtitle(displayCurrency: String) -> String {
        String.localizedStringWithFormat(screenSubtitleFormat, displayCurrency)
    }

    public static let disclaimer = NSLocalizedString(
        "Additional bank fees may apply. Your bank may add fee and Exchange Rates to each transaction.",
        comment: "Trading Currency Selection Screen: Disclaimer"
    )
}
