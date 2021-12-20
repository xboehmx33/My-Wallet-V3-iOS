// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import MoneyKit
@testable import PlatformKit
import RxRelay
import RxSwift
import XCTest

@testable import NetworkKitMock
@testable import PlatformKitMock
@testable import ToolKitMock

class PaymentAccountServiceTests: XCTestCase {
    var disposeBag: DisposeBag!
    var sut: PaymentAccountService!
    var dataRepository: DataRepositoryMock!
    var client: SimpleBuyPaymentAccountClientAPIMock!
    private var fiatCurrencyService: FiatCurrencySettingsServiceMock!
    private let fiatCurrency = FiatCurrency.GBP

    override func setUp() {
        super.setUp()
        disposeBag = DisposeBag()
        dataRepository = DataRepositoryMock()
        client = SimpleBuyPaymentAccountClientAPIMock()
        fiatCurrencyService = FiatCurrencySettingsServiceMock(
            expectedCurrency: fiatCurrency
        )
        sut = PaymentAccountService(
            client: client,
            dataRepository: dataRepository,
            fiatCurrencyService: fiatCurrencyService
        )
    }

    override func tearDown() {
        super.tearDown()
        disposeBag = nil
        dataRepository = nil
        client = nil
        sut = nil
    }

//    func testSuccessScenario() {
//        client.mockResponse = PaymentAccountResponse.mock(with: .GBP, agent: .fullMock)
//        let finishes = expectation(description: "finishes")
//        sut
//            .paymentAccount(for: .GBP)
//            .subscribe(onSuccess: { _ in
//                finishes.fulfill()
//            }, onError: { _ in
//                XCTFail("action should not have errored")
//            })
//            .disposed(by: disposeBag)
//        waitForExpectations(timeout: 5)
//    }

//    func testErrorRaisedForInvalidResponse() {
//        client.mockResponse = PaymentAccountResponse.mock(with: .GBP, agent: .emptyMock)
//        let fails = expectation(description: "fails")
//        sut
//            .paymentAccount(for: .GBP)
//            .subscribe(onSuccess: { _ in
//                XCTFail("action should not have succeeded")
//            }, onError: { _ in
//                fails.fulfill()
//            })
//            .disposed(by: disposeBag)
//        waitForExpectations(timeout: 5)
//    }
}
