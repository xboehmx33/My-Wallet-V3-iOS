// Copyright © Blockchain Luxembourg S.A. All rights reserved.
// swiftlint:disable all

import Foundation

public enum Localization {}

extension Localization {

    public enum Error {

        public static let title = NSLocalizedString(
            "Oops! Something went wrong",
            comment: "The title for an error explaining to the user that something went wrong."
        )

        public static let subtitle = NSLocalizedString(
            "We are unable to continue. Please contact support.",
            comment: "The body message of an error explaining to the user that they must contact support."
        )

        public static let network = NSLocalizedString(
            "It looks like there is a problem communicating with Blockchain.com. We are unable to continue, please try again later.",
            comment: "The body message of a network error"
        )
    }

    public enum InstitutionList {

        public static let title = NSLocalizedString(
            "Find your Bank",
            comment: "The title shown when the customer is selecting their bank from the list."
        )

        public static let search = NSLocalizedString(
            "Search",
            comment: "The search placeholder shown when the customer has not typed any term in the search bar."
        )

        public enum Error {

            public static let invalidAccount = NSLocalizedString(
                "You’ve tried to link an invalid account. Please try another account or contact support.",
                comment: "An error describing that the bank account the customer is trying to link via Open Banking is not valid."
            )

            public static let couldNotFindBank = NSLocalizedString(
                "We couldn’t find your bank. Send funds from your bank to your Blockchain Wallet with a Manual Transfer.",
                comment: "An error shown when the user searches for a bank and it's not available, this is the label shown in an empty state which also shows a button to allow the customer to setup a manual bank transfer."
            )

            public static let showTransferDetails = NSLocalizedString(
                "Show Transfer Details",
                comment: "The title of a button shown when the user has failed to find their bank and a manual transfer is offered instead. This is a primary button."
            )
        }
    }

    public enum Approve {

        public enum Action {

            public static let approve = NSLocalizedString(
                "Approve",
                comment: "A primary button moving the customer to the next step, this button confirms their acceptance to the terms and conditions/"
            )

            public static let deny = NSLocalizedString(
                "Deny",
                comment: "A destructive button to push the customer back, they deny the terms and conditions outlined on the approval page."
            )
        }

        public enum Payment {

            public static let in90Days = NSLocalizedString(
                "90 Days",
                comment: "The default message shown if we cannot compute a date 90 days in the future. This date is used to explain that access to OpenBanking services will expire in 90 days."
            )

            public static let approveYourPayment = NSLocalizedString(
                "Approve Your Payment",
                comment: "The title shown when a user is asked to approve an open banking transaction."
            )

            public static let paymentTotal = NSLocalizedString(
                "Payment total",
                comment: "A title which is used to show the total amount the customer is wanting to transact."
            )

            public static let paymentInformation = NSLocalizedString(
                "Payment Information",
                comment: "A title which is used to show the payment details that the customer has selected to use, this will be their bank information."
            )

            public static let bankName = NSLocalizedString(
                "Bank name",
                comment: "Bank name"
            )

            public static let sortCode = NSLocalizedString(
                "Sort Code",
                comment: "Sort Code"
            )

            public static let accountNumber = NSLocalizedString(
                "Account Number",
                comment: "Account Number"
            )

            public static let bank = NSLocalizedString(
                "Bank",
                comment: "A default value given if we do not know the customers bank name"
            )
        }

        public enum TermsAndConditions {

            public static let dataSharing = NSLocalizedString(
                "Data Sharing",
                comment: "Data Sharing terms and conditions title"
            )

            public static let dataSharingBody = NSLocalizedString(
                "%@ will retrieve your bank data based on your request and provide this information to Blockchain.com",
                comment: "Data Sharing Terms and conditions"
            )

            public static let secureConnection = NSLocalizedString(
                "Secure Connection",
                comment: "Secure Connection terms and conditions title"
            )

            public static let secureConnectionBody = NSLocalizedString(
                "Data is securely retrieved in read-only format and only for the duration agreed with you. You have the right to withdraw your consent at any time.",
                comment: "Secure Connection terms and conditions"
            )

            public static let FCAAuthorisation = NSLocalizedString(
                "FCA Authorisation",
                comment: "FCA Authorisation terms and conditions title"
            )

            public static let FCAAuthorisationBody1 = NSLocalizedString(
                "Blockchain.com is an agent of %@. %@ is authorised and regulated by the Financial Conduct Authority under the Payment Service Regulations 2017 [827001] for the provision of Account Information and Payment Initiation services.",
                comment: "FCA Authorisation terms and conditions. Interpolations for entity. e.g. SafeConnect"
            )

            public static let FCAAuthorisationBody2 = NSLocalizedString(
                "In order to share your %@ data with Blockchain.com, you will now be securely redirected to your bank to confirm your consent for %@ to read the following information:\n\n• Identification details\n• Account(s) details",
                comment: "FCA Authorisation terms and conditions. Interpolations for 1. bankName and 2. entity. e.g. Monzo and SafeConnect"
            )

            public static let aboutTheAccess = NSLocalizedString(
                "About the access",
                comment: "About the access terms and conditions title"
            )

            public static let aboutTheAccessBody = NSLocalizedString(
                "%@ will then use these details with Blockchain.com solely for the purposes of buying Cryptocurrency. This access is valid until %@, you can cancel consent at any time via the Blockchain.com settings or via your bank. This request is not a one-off, you will continue to receive consent requests as older versions expire.",
                comment: "About the access terms and conditions. Interpolations for 1. entity and 2. expiry. e.g. SafeConnect and September 17, 2021"
            )
        }
    }

    public enum Bank {

        public static let yourBank = NSLocalizedString(
            "Your Bank",
            comment: "A default value given if we could not determine the customers bank name."
        )

        public enum Action {

            public static let next = NSLocalizedString(
                "Next",
                comment: "A button to continue to the next step in Open Banking."
            )

            public static let ok = NSLocalizedString(
                "Ok",
                comment: "A button shown at the end of the Open Banking journey to exit and go back to where they were before."
            )

            public static let retry = NSLocalizedString(
                "Retry",
                comment: "A button to retry the last step in Open Banking."
            )

            public static let tryADifferentBank = NSLocalizedString(
                "Try a Different Bank",
                comment: "A button to select a new banking institution in the event of an error."
            )

            public static let tryAgain = NSLocalizedString(
                "Try again",
                comment: "A button to retry the last step in Open Banking."
            )

            public static let tryAnotherMethod = NSLocalizedString(
                "Try another method",
                comment: "A button to retry the last step in Open Banking."
            )

            public static let back = NSLocalizedString(
                "Go back",
                comment: "A button to reset the progress in Open Banking to start the entire process again."
            )

            public static let cancel = NSLocalizedString(
                "Cancel & Go Back",
                comment: "A button to reset the progress in Open Banking to start the entire process again."
            )
        }

        public enum Communicating {

            public static let title = NSLocalizedString(
                "Taking you to %@",
                comment: "Taking you to {Bank}"
            )

            public static let subtitle = NSLocalizedString(
                "This could take up to 30 seconds. Please do not go back or close the app.",
                comment: "This could take up to 30 seconds. Please do not go back or close the app."
            )
        }

        public enum Waiting {

            public static let title = NSLocalizedString(
                "Waiting to hear from %@",
                comment: "Waiting to hear from {Bank}"
            )

            public static let subtitle = NSLocalizedString(
                "This could take up to 30 seconds. Please do not go back or close the app.",
                comment: "This could take up to 30 seconds. Please do not go back or close the app."
            )
        }

        public enum Updating {

            public static let title = NSLocalizedString(
                "Updating your wallet...",
                comment: "Updating your wallet..."
            )

            public static let subtitle = NSLocalizedString(
                "This could take up to 30 seconds. Please do not go back or close the app.",
                comment: "This could take up to 30 seconds. Please do not go back or close the app."
            )
        }

        public enum Linked {

            public static let title = NSLocalizedString(
                "Bank Linked!",
                comment: "Bank Linked!"
            )

            public static let subtitle = NSLocalizedString(
                "Your %@ account is now linked to your Blockchain.com Wallet.",
                comment: "Your {Bank} account is now linked to your Blockchain.com Wallet."
            )
        }

        public enum Payment {

            public static let title = NSLocalizedString(
                "%@ added!",
                comment: "{Amount} added! e.g. £100 added!"
            )

            public static let subtitle = NSLocalizedString(
                "While we wait for your bank to send the cash, here’s early access to %@ in your %@ Cash Account so you can buy crypto right away. Your funds will be available to withdraw once the bank transfer is complete%@.",
                comment: "While we wait for your bank to send the cash, here’s early access to %@ in your %@ Cash Account so you can buy crypto right away. Your funds will be available to withdraw once the bank transfer is complete on %@."
            )

            public static let error = NSLocalizedString(
                "%@ is not a supported currency!",
                comment: "{Currency} is not a supported currency! e.g. Martian Dollars is not a supported currency!"
            )
        }

        public enum Buying {

            public static let title = NSLocalizedString(
                "Buying %@",
                comment: "e.g. Buying 0.0052568 BTC"
            )

            public static let subtitle = NSLocalizedString(
                "Order is being processed, we will let you know when its done. You can safely close this sheet while we update the order in the background.",
                comment: "Order is being processed, we will let you know when its done. You can safely close this sheet while we update the order in the background."
            )
        }

        public enum Buy {

            public static let title = NSLocalizedString(
                "%@ Purchased",
                comment: "e.g. 0.0052568 BTC Purchased"
            )

            public static let subtitle = NSLocalizedString(
                "These funds are available now to Sell & Swap. Note: You will not be able to Send or Withdraw these funds from your Wallet.",
                comment: "These funds are available now to Sell & Swap. Note: You will not be able to Send or Withdraw these funds from your Wallet."
            )
        }

        public enum Error {

            public static let bankTransferAccountNameMismatch = (
                title: NSLocalizedString(
                    "Is this your bank?",
                    comment: "Is this your bank?"
                ),
                subtitle: NSLocalizedString(
                    "We noticed the names don’t match. The bank you link must have a matching legal first & last name as your Blockchain.com Account.",
                    comment: "We noticed the names don’t match. The bank you link must have a matching legal first & last name as your Blockchain.com Account."
                ),
                action: Bank.Action.tryADifferentBank
            )

            public static let bankTransferAccountExpired = (
                title: NSLocalizedString(
                    "Access Request Expired",
                    comment: "Access Request Expired"
                ),
                subtitle: NSLocalizedString(
                    "The request to pair your account has timed out. Try pairing your account again. If this keeps happening, please contact support.",
                    comment: "The request to pair your account has timed out. Try pairing your account again. If this keeps happening, please contact support."
                ),
                action: Bank.Action.tryAgain
            )

            public static let bankTransferAccountFailed = (
                title: NSLocalizedString(
                    "Failed Connection Request",
                    comment: "Failed Connection Request"
                ),
                subtitle: NSLocalizedString(
                    "There's an issue connecting your bank. Please try again or use another payment method. If this keeps happening, please contact support.",
                    comment: "There's an issue connecting your bank. Please try again or use another payment method. If this keeps happening, please contact support."
                ),
                action: Bank.Action.tryAgain
            )

            public static let bankTransferAccountRejected = (
                title: NSLocalizedString(
                    "Connection Rejected",
                    comment: "Connection Rejected"
                ),
                subtitle: NSLocalizedString(
                    "We believe you have declined linking your account. If this isn't correct, please contact support.",
                    comment: "We believe you have declined linking your account. If this isn't correct, please contact support."
                ),
                action: Bank.Action.tryAgain
            )

            public static let bankTransferAccountInvalid = (
                title: NSLocalizedString(
                    "Invalid Account",
                    comment: "Invalid Account"
                ),
                subtitle: NSLocalizedString(
                    "You’ve tried to link an invalid account. Please try another account or contact support.",
                    comment: "You’ve tried to link an invalid account. Please try another account or contact support."
                ),
                action: Bank.Action.tryAgain
            )

            public static let bankTransferAccountAlreadyLinked = (
                title: NSLocalizedString(
                    "Account Already Linked",
                    comment: "Account Already Linked"
                ),
                subtitle: NSLocalizedString(
                    "We noticed this account is already active on another Wallet. If you believe this is incorrect, contact support.",
                    comment: "We noticed this account is already active on another Wallet. If you believe this is incorrect, contact support."
                ),
                action: Bank.Action.tryAgain
            )

            public static let bankTransferAccountNotSupported = (
                title: NSLocalizedString(
                    "Please link a Current Account.",
                    comment: "Please link a Current Account."
                ),
                subtitle: NSLocalizedString(
                    "Your bank may charge you extra fees if you buy crypto without a current account.",
                    comment: "Your bank may charge you extra fees if you buy crypto without a current account."
                ),
                action: Bank.Action.back
            )

            public static let bankTransferAccountFailedInternal = (
                title: NSLocalizedString(
                    "There was a problem linking your checking account ending in %@. Please try again.",
                    comment: "There was a problem linking your checking account ending in |last{4}|. Please try again."
                ),
                subtitle: NSLocalizedString(
                    "Please try again or select a different payment method.",
                    comment: "Please try again or select a different payment method."
                ),
                action: Bank.Action.tryAnotherMethod
            )

            public static let bankTransferAccountRejectedFraud = (
                title: NSLocalizedString(
                    "There was a problem linking your checking account ending in %@. Please try again.",
                    comment: "There was a problem linking your checking account ending in |last{4}|. Please try again."
                ),
                subtitle: NSLocalizedString(
                    "Please try again or select a different payment method.",
                    comment: "Please try again or select a different payment method."
                ),
                action: Bank.Action.tryAgain
            )

            public static let `default` = (
                title: Localization.Error.title,
                subtitle: NSLocalizedString(
                    "Please try linking your bank again. If this keeps happening, please contact support.",
                    comment: "Please try linking your bank again. If this keeps happening, please contact support."
                ),
                action: Bank.Action.tryAgain
            )

            public static let message = (
                title: Localization.Error.title,
                action: Bank.Action.tryAgain
            )

            public static let failedToGetPaymentDetails = NSLocalizedString(
                "Failed to get payment details",
                comment: "Failed to get payment details"
            )
        }
    }
}
