// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import MoneyKit

public enum TransactionConfirmation: TransactionConfirmationModelable {

    case arrivalDate(TransactionConfirmation.Model.FundsArrivalDate)
    case bitpayCountdown(TransactionConfirmation.Model.BitPayCountdown)
    case buyCryptoValue(TransactionConfirmation.Model.BuyCryptoValue)
    case buyExchangeRateValue(TransactionConfirmation.Model.BuyExchangeRateValue)
    case buyPaymentMethod(TransactionConfirmation.Model.BuyPaymentMethodValue)
    case description(TransactionConfirmation.Model.Description)
    case destination(TransactionConfirmation.Model.Destination)
    case errorNotice(TransactionConfirmation.Model.ErrorNotice)
    case exchangePrice(TransactionConfirmation.Model.ExchangePriceOption)
    case feedTotal(TransactionConfirmation.Model.FeedTotal)
    case feeSelection(TransactionConfirmation.Model.FeeSelection)
    case imageNotice(TransactionConfirmation.Model.ImageNotice)
    case largeTransactionWarning(TransactionConfirmation.Model.AnyBoolOption<MoneyValue>)
    case memo(TransactionConfirmation.Model.Memo)
    case message(TransactionConfirmation.Model.Message)
    case network(TransactionConfirmation.Model.Network)
    case networkFee(TransactionConfirmation.Model.NetworkFee)
    case notice(TransactionConfirmation.Model.Notice)
    case purchase(TransactionConfirmation.Model.Purchase)
    case rawTransaction(TransactionConfirmation.Model.RawTransaction)
    case sellDestinationValue(TransactionConfirmation.Model.SellDestinationValue)
    case sellExchangeRateValue(TransactionConfirmation.Model.SellExchangeRateValue)
    case sellSourceValue(TransactionConfirmation.Model.SellSourceValue)
    case sendDestinationValue(TransactionConfirmation.Model.SendDestinationValue)
    case source(TransactionConfirmation.Model.Source)
    case swapDestinationValue(TransactionConfirmation.Model.SwapDestinationValue)
    case swapExchangeRate(TransactionConfirmation.Model.SwapExchangeRate)
    case swapSourceValue(TransactionConfirmation.Model.SwapSourceValue)
    case termsOfService(TransactionConfirmation.Model.AnyBoolOption<Bool>)
    case total(TransactionConfirmation.Model.Total)
    case totalCost(TransactionConfirmation.Model.TotalCost)
    case transactionFee(TransactionConfirmation.Model.FiatTransactionFee)
    case transferAgreement(TransactionConfirmation.Model.AnyBoolOption<Bool>)

    public var type: TransactionConfirmation.Kind {
        switch self {
        case .arrivalDate(let model):
            return model.type
        case .bitpayCountdown(let model):
            return model.type
        case .buyCryptoValue(let model):
            return model.type
        case .buyExchangeRateValue(let model):
            return model.type
        case .buyPaymentMethod(let model):
            return model.type
        case .description(let model):
            return model.type
        case .destination(let model):
            return model.type
        case .errorNotice(let model):
            return model.type
        case .exchangePrice(let model):
            return model.type
        case .feedTotal(let model):
            return model.type
        case .feeSelection(let model):
            return model.type
        case .imageNotice(let model):
            return model.type
        case .largeTransactionWarning(let model):
            return model.type
        case .memo(let model):
            return model.type
        case .message(let model):
            return model.type
        case .network(let model):
            return model.type
        case .networkFee(let model):
            return model.type
        case .notice(let model):
            return model.type
        case .rawTransaction(let model):
            return model.type
        case .sellDestinationValue(let model):
            return model.type
        case .sellExchangeRateValue(let model):
            return model.type
        case .sellSourceValue(let model):
            return model.type
        case .sendDestinationValue(let model):
            return model.type
        case .source(let model):
            return model.type
        case .swapDestinationValue(let model):
            return model.type
        case .swapExchangeRate(let model):
            return model.type
        case .swapSourceValue(let model):
            return model.type
        case .termsOfService(let model):
            return model.type
        case .total(let model):
            return model.type
        case .totalCost(let model):
            return model.type
        case .purchase(let model):
            return model.type
        case .transactionFee(let model):
            return model.type
        case .transferAgreement(let model):
            return model.type
        }
    }

    public var formatted: (title: String, subtitle: String)? {
        switch self {
        case .arrivalDate(let model):
            return model.formatted
        case .bitpayCountdown(let model):
            return model.formatted
        case .buyCryptoValue(let model):
            return model.formatted
        case .buyExchangeRateValue(let model):
            return model.formatted
        case .buyPaymentMethod(let model):
            return model.formatted
        case .description(let model):
            return model.formatted
        case .destination(let model):
            return model.formatted
        case .errorNotice(let model):
            return model.formatted
        case .exchangePrice(let model):
            return model.formatted
        case .feedTotal(let model):
            return model.formatted
        case .feeSelection(let model):
            return model.formatted
        case .imageNotice(let model):
            return model.formatted
        case .largeTransactionWarning(let model):
            return model.formatted
        case .memo(let model):
            return model.formatted
        case .message(let model):
            return model.formatted
        case .network(let model):
            return model.formatted
        case .networkFee(let model):
            return model.formatted
        case .notice(let model):
            return model.formatted
        case .rawTransaction(let model):
            return model.formatted
        case .sellDestinationValue(let model):
            return model.formatted
        case .sellExchangeRateValue(let model):
            return model.formatted
        case .sellSourceValue(let model):
            return model.formatted
        case .sendDestinationValue(let model):
            return model.formatted
        case .source(let model):
            return model.formatted
        case .swapDestinationValue(let model):
            return model.formatted
        case .swapExchangeRate(let model):
            return model.formatted
        case .swapSourceValue(let model):
            return model.formatted
        case .termsOfService(let model):
            return model.formatted
        case .total(let model):
            return model.formatted
        case .totalCost(let model):
            return model.formatted
        case .purchase(let model):
            return model.formatted
        case .transactionFee(let model):
            return model.formatted
        case .transferAgreement(let model):
            return model.formatted
        }
    }

    /// Is equal ignoring associated value.
    public func bareCompare(to rhs: Self) -> Bool {
        switch (self, rhs) {
        case (.arrivalDate, .arrivalDate),
             (.bitpayCountdown, .bitpayCountdown),
             (.buyCryptoValue, .buyCryptoValue),
             (.buyExchangeRateValue, .buyExchangeRateValue),
             (.buyPaymentMethod, .buyPaymentMethod),
             (.description, .description),
             (.destination, .destination),
             (.errorNotice, .errorNotice),
             (.exchangePrice, .exchangePrice),
             (.feedTotal, .feedTotal),
             (.feeSelection, .feeSelection),
             (.imageNotice, .imageNotice),
             (.largeTransactionWarning, .largeTransactionWarning),
             (.memo, .memo),
             (.message, .message),
             (.network, .network),
             (.networkFee, .networkFee),
             (.notice, .notice),
             (.rawTransaction, .rawTransaction),
             (.sellDestinationValue, .sellDestinationValue),
             (.sellExchangeRateValue, .sellExchangeRateValue),
             (.sellSourceValue, .sellSourceValue),
             (.sendDestinationValue, .sendDestinationValue),
             (.source, .source),
             (.swapDestinationValue, .swapDestinationValue),
             (.swapExchangeRate, .swapExchangeRate),
             (.swapSourceValue, .swapSourceValue),
             (.termsOfService, .termsOfService),
             (.total, .total),
             (.totalCost, .totalCost),
             (.purchase, .purchase),
             (.transactionFee, .transactionFee),
             (.transferAgreement, .transferAgreement):
            return true
        default:
            return false
        }
    }
}
