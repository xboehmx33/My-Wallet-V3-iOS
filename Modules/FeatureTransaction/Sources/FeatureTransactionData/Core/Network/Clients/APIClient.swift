// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import DIKit
import FeatureTransactionDomain
import MoneyKit
import NabuNetworkError
import NetworkKit
import PlatformKit
import ToolKit

typealias FeatureTransactionDomainClientAPI = CustodialQuoteAPI &
    OrderCreationClientAPI &
    AvailablePairsClientAPI &
    TransactionLimitsClientAPI &
    OrderFetchingClientAPI &
    OrderUpdateClientAPI &
    CustodialTransferClientAPI &
    BitPayClientAPI &
    BlockchainNameResolutionClientAPI &
    BankTransferClientAPI

/// FeatureTransactionDomain network client
final class APIClient: FeatureTransactionDomainClientAPI {

    // MARK: - Types

    fileprivate enum Parameter {
        static let minor = "minor"
        static let networkFee = "networkFee"
        static let currency = "currency"
        static let inputCurrency = "inputCurrency"
        static let fromAccount = "fromAccount"
        static let outputCurrency = "outputCurrency"
        static let toAccount = "toAccount"
        static let product = "product"
        static let paymentMethod = "paymentMethod"
        static let orderDirection = "orderDirection"
        static let payment = "payment"
        static let simpleBuy = "SIMPLEBUY"
        static let swap = "SWAP"
        static let sell = "SELL"
        static let `default` = "DEFAULT"
    }

    private enum Path {
        static let quote = ["custodial", "quote"]
        static let createOrder = ["custodial", "trades"]
        static let availablePairs = ["custodial", "trades", "pairs"]
        static let fetchOrder = createOrder
        static let limits = ["trades", "limits"]
        static let crossBorderLimits = ["limits", "crossborder", "transaction"]
        static let transfer = ["payments", "withdrawals"]
        static let bankTransfer = ["payments", "banktransfer"]
        static let transferFees = ["payments", "withdrawals", "fees"]
        static let domainResolution = ["resolve"]

        static func updateOrder(transactionID: String) -> [String] {
            createOrder + [transactionID]
        }
    }

    private enum BitPay {
        static let url: String = "https://bitpay.com/"

        enum Paramter {
            static let invoice: String = "i/"
        }
    }

    // MARK: - Properties

    private let retailNetworkAdapter: NetworkAdapterAPI
    private let retailRequestBuilder: RequestBuilder
    private let defaultNetworkAdapter: NetworkAdapterAPI
    private let defaultRequestBuilder: RequestBuilder

    // MARK: - Setup

    init(
        retailNetworkAdapter: NetworkAdapterAPI = DIKit.resolve(tag: DIKitContext.retail),
        retailRequestBuilder: RequestBuilder = DIKit.resolve(tag: DIKitContext.retail),
        defaultNetworkAdapter: NetworkAdapterAPI = DIKit.resolve(),
        defaultRequestBuilder: RequestBuilder = DIKit.resolve()
    ) {
        self.retailNetworkAdapter = retailNetworkAdapter
        self.retailRequestBuilder = retailRequestBuilder
        self.defaultNetworkAdapter = defaultNetworkAdapter
        self.defaultRequestBuilder = defaultRequestBuilder
    }

    // MARK: - AvailablePairsClientAPI

    var availableOrderPairs: AnyPublisher<AvailableTradingPairsResponse, NabuNetworkError> {
        let request = retailRequestBuilder.get(
            path: Path.availablePairs,
            authenticated: true
        )!
        return retailNetworkAdapter.perform(request: request)
    }

    // MARK: - CustodialQuoteAPI

    func fetchQuoteResponse(
        with request: OrderQuoteRequest
    ) -> AnyPublisher<OrderQuoteResponse, NabuNetworkError> {
        let request = retailRequestBuilder.post(
            path: Path.quote,
            body: try? request.encode(),
            authenticated: true
        )!
        return retailNetworkAdapter.perform(request: request)
    }

    // MARK: - OrderCreationClientAPI

    func create(
        direction: OrderDirection,
        quoteIdentifier: String,
        volume: MoneyValue,
        destinationAddress: String?,
        refundAddress: String?
    ) -> AnyPublisher<SwapActivityItemEvent, NabuNetworkError> {
        create(
            direction: direction,
            quoteIdentifier: quoteIdentifier,
            volume: volume,
            destinationAddress: destinationAddress,
            refundAddress: refundAddress,
            ccy: nil
        )
    }

    func create(
        direction: OrderDirection,
        quoteIdentifier: String,
        volume: MoneyValue,
        ccy: String?
    ) -> AnyPublisher<SwapActivityItemEvent, NabuNetworkError> {
        create(
            direction: direction,
            quoteIdentifier: quoteIdentifier,
            volume: volume,
            destinationAddress: nil,
            refundAddress: nil,
            ccy: ccy
        )
    }

    private func create(
        direction: OrderDirection,
        quoteIdentifier: String,
        volume: MoneyValue,
        destinationAddress: String?,
        refundAddress: String?,
        ccy: String?
    ) -> AnyPublisher<SwapActivityItemEvent, NabuNetworkError> {
        let body = OrderCreationRequest(
            direction: direction,
            quoteId: quoteIdentifier,
            volume: volume,
            destinationAddress: destinationAddress,
            refundAddress: refundAddress,
            ccy: ccy
        )
        let request = retailRequestBuilder.post(
            path: Path.createOrder,
            body: try? body.encode(),
            authenticated: true
        )!
        return retailNetworkAdapter.perform(request: request)
    }

    // MARK: - OrderUpdateClientAPI

    func updateOrder(
        with transactionId: String,
        success: Bool
    ) -> AnyPublisher<Void, NabuNetworkError> {
        let payload = OrderUpdateRequest(success: success)
        let request = retailRequestBuilder.post(
            path: Path.updateOrder(transactionID: transactionId),
            body: try? payload.encode(),
            authenticated: true
        )!
        return retailNetworkAdapter.perform(request: request)
    }

    // MARK: - OrderFetchingClientAPI

    func fetchTransaction(
        with transactionId: String
    ) -> AnyPublisher<SwapActivityItemEvent, NabuNetworkError> {
        let request = retailRequestBuilder.get(
            path: Path.fetchOrder + [transactionId],
            authenticated: true
        )!
        return retailNetworkAdapter.perform(request: request)
    }

    // MARK: - CustodialTransferClientAPI

    func send(
        transferRequest: CustodialTransferRequest
    ) -> AnyPublisher<CustodialTransferResponse, NabuNetworkError> {
        let headers = [HttpHeaderField.blockchainOrigin: HttpHeaderValue.simpleBuy]
        let request = retailRequestBuilder.post(
            path: Path.transfer,
            body: try? transferRequest.encode(),
            headers: headers,
            authenticated: true
        )!
        return retailNetworkAdapter.perform(request: request)
    }

    func custodialTransferFeesForProduct(
        _ product: Product
    ) -> AnyPublisher<CustodialTransferFeesResponse, NabuNetworkError> {
        let parameters: [URLQueryItem] = [
            URLQueryItem(name: Parameter.product, value: product.rawValue),
            URLQueryItem(name: Parameter.paymentMethod, value: Parameter.default)
        ]
        let request = retailRequestBuilder.get(
            path: Path.transferFees,
            parameters: parameters,
            authenticated: false
        )!
        return retailNetworkAdapter.perform(request: request)
    }

    func custodialTransferFees() -> AnyPublisher<CustodialTransferFeesResponse, NabuNetworkError> {
        let headers = [HttpHeaderField.blockchainOrigin: HttpHeaderValue.simpleBuy]
        let parameters: [URLQueryItem] = [
            URLQueryItem(name: Parameter.product, value: Parameter.simpleBuy),
            URLQueryItem(name: Parameter.paymentMethod, value: Parameter.default)
        ]
        let request = retailRequestBuilder.get(
            path: Path.transferFees,
            parameters: parameters,
            headers: headers,
            authenticated: false
        )!
        return retailNetworkAdapter.perform(request: request)
    }

    // MARK: - BankTransferClientAPI

    func startBankTransfer(
        id: String,
        amount: MoneyValue
    ) -> AnyPublisher<BankTranferPaymentResponse, NabuNetworkError> {
        let model = BankTransferPaymentRequest(
            amountMinor: amount.minorString,
            currency: amount.code,
            attributes: nil
        )
        let request = retailRequestBuilder.post(
            path: Path.bankTransfer + [id] + [Parameter.payment],
            body: try? model.encode(),
            authenticated: true
        )!
        return retailNetworkAdapter.perform(request: request)
    }

    func createWithdrawOrder(id: String, amount: MoneyValue) -> AnyPublisher<Void, NabuNetworkError> {
        let headers = [HttpHeaderField.blockchainOrigin: HttpHeaderValue.simpleBuy]
        let body = WithdrawRequestBody(
            beneficiary: id,
            currency: amount.code,
            amount: amount.minorString
        )
        let request = retailRequestBuilder.post(
            path: Path.transfer,
            body: try? body.encode(),
            headers: headers,
            authenticated: true
        )!
        return retailNetworkAdapter.perform(request: request)
    }

    // MARK: - BitPayClientAPI

    func bitpayPaymentRequest(
        invoiceId: String,
        currency: CryptoCurrency
    ) -> AnyPublisher<BitpayPaymentRequestResponse, NetworkError> {
        let payload = ["chain": currency.code]
        let headers = [
            HttpHeaderField.xPayProVersion: HttpHeaderValue.xPayProVersion,
            HttpHeaderField.contentType: HttpHeaderValue.bitpayPaymentRequest,
            HttpHeaderField.bitpayPartner: HttpHeaderValue.bitpayPartnerName,
            HttpHeaderField.bitpayPartnerVersion: HttpHeaderValue.bitpayPartnerVersion
        ]
        let url = URL(string: BitPay.url + BitPay.Paramter.invoice + invoiceId)!
        let request = NetworkRequest(
            endpoint: url,
            method: .post,
            body: try? JSONEncoder().encode(payload),
            headers: headers
        )
        return retailNetworkAdapter.perform(request: request)
    }

    func verifySignedTransaction(
        invoiceId: String,
        currency: CryptoCurrency,
        transactionHex: String,
        transactionSize: Int
    ) -> AnyPublisher<Void, NetworkError> {
        let transaction = BitPayPaymentRequest.Transaction(
            tx: transactionHex,
            weightedSize: transactionSize
        )
        let payload = BitPayPaymentRequest(
            chain: currency.code,
            transactions: [transaction]
        )
        let headers = [
            HttpHeaderField.xPayProVersion: HttpHeaderValue.xPayProVersion,
            HttpHeaderField.contentType: HttpHeaderValue.bitpayPaymentVerification,
            HttpHeaderField.bitpayPartner: HttpHeaderValue.bitpayPartnerName,
            HttpHeaderField.bitpayPartnerVersion: HttpHeaderValue.bitpayPartnerVersion
        ]
        let url = URL(string: BitPay.url + BitPay.Paramter.invoice + invoiceId)!
        let request = NetworkRequest(
            endpoint: url,
            method: .post,
            body: try? JSONEncoder().encode(payload),
            headers: headers
        )
        return retailNetworkAdapter.perform(request: request)
    }

    func postPayment(
        invoiceId: String,
        currency: CryptoCurrency,
        transactionHex: String,
        transactionSize: Int
    ) -> AnyPublisher<BitPayMemoResponse, NetworkError> {
        let transaction = BitPayPaymentRequest.Transaction(
            tx: transactionHex,
            weightedSize: transactionSize
        )
        let payload = BitPayPaymentRequest(
            chain: currency.code,
            transactions: [transaction]
        )
        let headers = [
            HttpHeaderField.xPayProVersion: HttpHeaderValue.xPayProVersion,
            HttpHeaderField.contentType: HttpHeaderValue.bitpayPayment,
            HttpHeaderField.bitpayPartner: HttpHeaderValue.bitpayPartnerName,
            HttpHeaderField.bitpayPartnerVersion: HttpHeaderValue.bitpayPartnerVersion
        ]
        let url = URL(string: BitPay.url + BitPay.Paramter.invoice + invoiceId)!
        let request = NetworkRequest(
            endpoint: url,
            method: .post,
            body: try? JSONEncoder().encode(payload),
            headers: headers
        )
        return retailNetworkAdapter.perform(request: request)
    }

    // MARK: - TransactionLimitsClientAPI

    func fetchTradeLimits(
        currency: CurrencyType,
        networkFee: CurrencyType,
        product: TransactionLimitsProduct
    ) -> AnyPublisher<TradeLimitsResponse, NabuNetworkError> {
        var parameters: [URLQueryItem] = [
            URLQueryItem(
                name: Parameter.currency,
                value: currency.code
            ),
            URLQueryItem(
                name: Parameter.networkFee,
                value: networkFee.code
            ),
            URLQueryItem(
                name: Parameter.minor,
                value: "true"
            )
        ]
        switch product {
        case .swap(let orderDirection):
            parameters.append(
                URLQueryItem(name: Parameter.product, value: Parameter.swap)
            )
            parameters.append(
                URLQueryItem(name: Parameter.orderDirection, value: orderDirection.rawValue)
            )
        case .sell(let orderDirection):
            parameters.append(
                URLQueryItem(name: Parameter.product, value: Parameter.sell)
            )
            parameters.append(
                URLQueryItem(name: Parameter.orderDirection, value: orderDirection.rawValue)
            )
        case .simplebuy:
            parameters.append(
                URLQueryItem(name: Parameter.product, value: Parameter.simpleBuy)
            )
        }
        let request = retailRequestBuilder.get(
            path: Path.limits,
            parameters: parameters,
            authenticated: true
        )!
        return retailNetworkAdapter.perform(request: request)
    }

    func fetchCrossBorderLimits(
        source: LimitsAccount,
        destination: LimitsAccount,
        limitsCurrency: CurrencyType
    ) -> AnyPublisher<CrossBorderLimitsResponse, NabuNetworkError> {
        let parameters: [URLQueryItem] = [
            URLQueryItem(name: Parameter.currency, value: limitsCurrency.code),
            URLQueryItem(name: Parameter.inputCurrency, value: source.currency.code),
            URLQueryItem(name: Parameter.fromAccount, value: source.accountType.rawValue),
            URLQueryItem(name: Parameter.outputCurrency, value: destination.currency.code),
            URLQueryItem(name: Parameter.toAccount, value: destination.accountType.rawValue)
        ]
        let request = retailRequestBuilder.get(
            path: Path.crossBorderLimits,
            parameters: parameters,
            authenticated: true
        )!
        return retailNetworkAdapter.perform(request: request)
    }

    // MARK: - BlockchainNameResolutionRepositoryAPI

    func resolve(
        domainName: String,
        currency: String
    ) -> AnyPublisher<DomainResolutionResponse, NetworkError> {
        let payload = DomainResolutionRequest(currency: currency, name: domainName)
        let request = defaultRequestBuilder.post(
            path: Path.domainResolution,
            body: try? JSONEncoder().encode(payload)
        )!
        return defaultNetworkAdapter.perform(request: request)
    }
}
