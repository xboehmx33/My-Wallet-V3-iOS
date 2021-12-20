// Copyright © Blockchain Luxembourg S.A. All rights reserved.
// swiftlint:disable line_length

#if canImport(SharedComponentLibrary)
import SharedComponentLibrary
#else
import ComponentLibrary
#endif

#if DEBUG
extension TaskView_Previews {

    static func payment() -> Task {
        let header = Task.group(
            Task.label("Approve Your Payment")
                .typography(.title3),
            Task.spacer(4.vmin),
            Task.group(
                Task.divider(),
                Task.row("Payment total", value: "£100.00")
                    .padding([.top, .bottom], 8.pt),
                Task.divider()
            ),
            Task.spacer(4.vmin)
        )

        let information = Task.section(
            header: "Payment Information",
            expandable: true,
            tasks: [
                Task.row("Bank name", value: "Monzo"),
                Task.row("Sort Code", value: "04-00-04"),
                Task.row("Account Number", value: "94936804")
            ]
        )

        return Task.group(
            header,
            information
        )
    }

    static func safeconnect() -> Task {
        Task.group(
            Task.section(
                header: "Data Sharing",
                expandable: true,
                tasks: [
                    Task.label("SafeConnect will retrieve your bank data based on your request and provide this information to Blockchain.com")
                ]
            ),
            Task.section(
                header: "Secure Connection",
                expandable: true,
                tasks: [
                    Task.label("Data is securely retrieved in read-only format and only for the duration agreed with you. You have the right to withdraw your consent at any time.")
                ]
            ),
            Task.section(
                header: "FCA Authorisation",
                expandable: true,
                tasks: [
                    .label("Blockchain.com is an agent of SafeConnect Ltd. SafeConnect Ltd is authorised and regulated by the Financial Conduct Authority under the Payment Service Regulations 2017 [827001] for the provision of Account Information and Payment Initiation services."),
                    .label("In order to share your Monzo data with Blockchain.com, you will now be securely redirected to your bank to confirm your consent for SafeConnect to read the following information:\n\n• Identification details\n• Account(s) details")
                ]
            ),
            Task.section(
                header: "About the access",
                expandable: true,
                tasks: [
                    Task.label("SafeConnect will then use these details with Blockchain.com solely for the purposes of buying Crypto. This access is valid until Tomorrow, you can cancel consent at any time via the Blockchain.com settings or via your bank. This request is not a one-off, you will continue to receive consent requests as older versions expire.")
                ]
            )
        )
        .typography(.paragraph1)
        .foreground(.textDetail)
    }
}
#endif
