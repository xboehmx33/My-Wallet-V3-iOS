// Copyright © Blockchain Luxembourg S.A. All rights reserved.

@testable import EthereumKit
@testable import EthereumKitMock
@testable import MoneyKit
@testable import PlatformKit
import RxSwift
import RxTest
import ToolKit
import XCTest

class EthereumAccountDetailsServiceTests: XCTestCase {

    var scheduler: TestScheduler!
    var disposeBag: DisposeBag!
    var accountRepository: EthereumWalletAccountRepositoryMock!
    var client: BalanceClientAPIMock!
    var subject: EthereumAccountDetailsService!

    override func setUp() {
        super.setUp()
        client = BalanceClientAPIMock()
        scheduler = TestScheduler(initialClock: 0)
        disposeBag = DisposeBag()
        accountRepository = EthereumWalletAccountRepositoryMock()
        subject = EthereumAccountDetailsService(
            accountRepository: accountRepository,
            client: client,
            scheduler: scheduler
        )
    }

    override func tearDown() {
        client = nil
        scheduler = nil
        disposeBag = nil
        accountRepository = nil
        subject = nil
        super.tearDown()
    }

    func test_get_account_details() {
        // Arrange
        let account = EthereumWalletAccount(
            index: 0,
            publicKey: MockEthereumWalletTestData.account,
            label: CryptoCurrency.coin(.ethereum).defaultWalletName,
            archived: false
        )
        let balanceDetails = BalanceDetailsResponse(balance: "2.0", nonce: 1)
        accountRepository.underlyingDefaultAccount = account
        client.balanceDetailsValue = .just(balanceDetails)

        let expectedAccountDetails = EthereumAssetAccountDetails(
            account: account,
            balance: balanceDetails.cryptoValue,
            nonce: balanceDetails.nonce
        )

        let sendObservable: Observable<EthereumAssetAccountDetails> = subject
            .accountDetails()
            .asObservable()

        // Act
        let result: TestableObserver<EthereumAssetAccountDetails> = scheduler
            .start { sendObservable }

        // Assert
        let expectedEvents: [Recorded<Event<EthereumAssetAccountDetails>>] = Recorded.events(
            .next(
                202,
                expectedAccountDetails
            ),
            .completed(203)
        )

        XCTAssertEqual(result.events, expectedEvents)
    }
}
