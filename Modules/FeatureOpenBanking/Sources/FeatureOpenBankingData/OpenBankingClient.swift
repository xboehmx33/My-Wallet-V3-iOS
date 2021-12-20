// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import CombineSchedulers
import FeatureOpenBankingDomain
import Foundation
import Session
import ToolKit

// swiftlint:disable force_try

// swiftlint:disable:next duplicate_imports
@_exported import struct ToolKit.Identity
// swiftlint:disable:next duplicate_imports
@_exported import protocol ToolKit.NewTypeString

public class OpenBankingClient {

    public typealias State = FeatureOpenBankingDomain.OpenBanking.State
    public private(set) var state: State

    public var scheduler: AnySchedulerOf<DispatchQueue>
    private var bag: Set<AnyCancellable> = []

    let requestBuilder: RequestBuilder
    let network: Network

    public convenience init(
        requestBuilder: RequestBuilder,
        network: Network,
        scheduler: DispatchQueue = .main
    ) {
        self.init(
            requestBuilder: requestBuilder,
            network: network,
            scheduler: scheduler.eraseToAnyScheduler(),
            state: .init()
        )
    }

    init(
        requestBuilder: RequestBuilder,
        network: Network,
        scheduler: AnySchedulerOf<DispatchQueue>,
        state: State
    ) {
        self.requestBuilder = requestBuilder
        self.network = network
        self.scheduler = scheduler
        self.state = state

        state.publisher(for: .consent.token, as: String.self)
            .sink(to: OpenBankingClient.handle(consent:), on: self)
            .store(in: &bag)
    }

    func handle(consent: Result<String, State.Error>) {

        if case .failure(.keyDoesNotExist) = consent {
            return
        }

        let callbackPath: String
        switch state.result(for: .callback.path, as: String.self) {
        case .success(let output):
            callbackPath = output
        case .failure(let error):
            return state.set(.consent.error, to: OpenBanking.Error.state(error))
        }

        switch consent {
        case .success(let oneTimeToken):
            let request = try! requestBuilder.post(
                path: callbackPath,
                body: [
                    "oneTimeToken": oneTimeToken
                ].json(),
                authenticated: true
            )
            network.perform(request: request)
                .mapError(OpenBanking.Error.init)
                .result()
                .sink(to: OpenBankingClient.handle(updateConsent:), on: self)
                .store(in: &bag)
        case .failure(let error):
            state.set(.consent.error, to: OpenBanking.Error.state(error))
        }
    }

    func handle(updateConsent result: Result<Void, Error>) {

        state.transaction { state in
            state.clear(.authorisation.url)
            state.clear(.consent.token)
            switch result {
            case .success:
                state.clear(.consent.error)
                state.set(.is.authorised, to: true)
            case .failure(let error):
                state.set(.consent.error, to: error)
                state.set(.is.authorised, to: false)
            }
        }
    }

    public func createBankAccount() -> AnyPublisher<OpenBanking.BankAccount, OpenBanking.Error> {

        switch state.result(for: .currency) {
        case .success(let currency):
            let request = try! requestBuilder.post(
                path: ["payments", "banktransfer"],
                body: [
                    "currency": currency
                ].json(),
                authenticated: true
            )

            return network.perform(request: request, responseType: OpenBanking.BankAccount.self)
                .handleEvents(receiveOutput: { [state] account in
                    state.transaction { state in
                        state.set(.id, to: account.id)
                        state.set(.account, to: account)
                    }
                })
                .mapError(OpenBanking.Error.init)
                .eraseToAnyPublisher()
        case .failure(let error):
            return Fail(error: .init(error)).eraseToAnyPublisher()
        }
    }

    public func fetchAllBankAccounts() -> AnyPublisher<[OpenBanking.BankAccount], OpenBanking.Error> {

        let request = requestBuilder.get(
            path: ["payments", "banktransfer"],
            authenticated: true
        )

        return network.perform(request: request, responseType: [OpenBanking.BankAccount].self)
            .mapError(OpenBanking.Error.init)
            .eraseToAnyPublisher()
    }

    public func confirm(
        order: Identity<OpenBanking.Order>,
        using paymentMethod: String
    ) -> AnyPublisher<OpenBanking.Order, OpenBanking.Error> {
        let request = try! requestBuilder.post(
            path: ["simple-buy", "trades", order.value],
            body: [
                "action": "confirm",
                "paymentMethodId": paymentMethod,
                "attributes": [
                    "callback": "https://blockchainwallet.page.link/obapproval"
                ]
            ].json(options: .sortedKeys),
            authenticated: true
        )

        return network.perform(request: request, responseType: OpenBanking.Order.self)
            .mapError(OpenBanking.Error.init)
            .eraseToAnyPublisher()
    }
}

extension OpenBanking.BankAccount {

    public func activateBankAccount(
        with institution: Identity<OpenBanking.Institution>,
        in banking: OpenBankingClient
    ) -> AnyPublisher<OpenBanking.BankAccount, OpenBanking.Error> {
        banking.state.transaction { state in
            state.clear(.authorisation.url)
            state.clear(.callback.path)
        }

        let request = try! banking.requestBuilder.post(
            path: ["payments", "banktransfer", id.value, "update"],
            body: [
                "attributes": [
                    "institutionId": institution.value,
                    "callback": "https://blockchainwallet.page.link/oblinking"
                ]
            ].json(),
            authenticated: true
        )

        return banking.network.perform(request: request, responseType: OpenBanking.BankAccount.self)
            .handleEvents(receiveOutput: { [banking] account in
                banking.state.transaction { state in
                    state.set(.account, to: account)
                }
            })
            .mapError(OpenBanking.Error.init)
            .eraseToAnyPublisher()
    }

    public func get(
        in banking: OpenBankingClient
    ) -> AnyPublisher<OpenBanking.BankAccount, OpenBanking.Error> {

        let request = banking.requestBuilder.get(
            path: ["payments", "banktransfer", id.value],
            authenticated: true
        )

        return banking.network.perform(request: request, responseType: OpenBanking.BankAccount.self)
            .handleEvents(receiveOutput: { [banking] account in
                guard let url = account.attributes.authorisationUrl else { return }
                guard let path = account.attributes.callbackPath else { return }
                banking.state.transaction { state in
                    state.set(.account, to: account)
                    state.set(.authorisation.url, to: url)
                    state.set(.callback.path, to: path.dropPrefix("nabu-gateway").string)
                }
            })
            .mapError(OpenBanking.Error.init)
            .eraseToAnyPublisher()
    }

    public func poll(
        in banking: OpenBankingClient,
        until condition: @escaping (OpenBanking.BankAccount) -> Bool = { $0.attributes.authorisationUrl != nil }
    ) -> AnyPublisher<OpenBanking.BankAccount, OpenBanking.Error> {
        Deferred {
            get(in: banking)
        }
        .poll(
            max: 60,
            until: { account in
                guard account.error == nil else { return true }
                return condition(account)
            },
            delay: .seconds(2),
            scheduler: banking.scheduler
        )
        .mapError(OpenBanking.Error.init)
        .eraseToAnyPublisher()
    }

    public func delete(
        in banking: OpenBankingClient
    ) -> AnyPublisher<OpenBanking.BankAccount, OpenBanking.Error> {
        let request = banking.requestBuilder.delete(
            path: ["payments", "banktransfer", id.value],
            authenticated: true
        )

        return banking.network.perform(request: request, responseType: OpenBanking.BankAccount.self)
            .handleEvents(receiveOutput: { [banking] _ in
                banking.state.clear(.id)
            })
            .mapError(OpenBanking.Error.init)
            .eraseToAnyPublisher()
    }

    public func deposit(
        amountMinor: String,
        product: String,
        in banking: OpenBankingClient
    ) -> AnyPublisher<OpenBanking.Payment, OpenBanking.Error> {
        switch banking.state.result(for: .currency) {
        case .success(let currency):
            let request = try! banking.requestBuilder.post(
                path: ["payments", "banktransfer", id.value, "payment"],
                body: [
                    "currency": currency,
                    "amountMinor": amountMinor,
                    "product": product,
                    "attributes": [
                        "callback": "https://blockchainwallet.page.link/obapproval"
                    ]
                ].json(options: .sortedKeys),
                authenticated: true
            )

            return banking.network.perform(request: request, responseType: OpenBanking.Payment.self)
                .handleEvents(receiveOutput: { [banking] payment in
                    let path = payment.attributes.callbackPath.dropPrefix("nabu-gateway").string
                    banking.state.set(.callback.path, to: path)
                })
                .mapError(OpenBanking.Error.init)
                .eraseToAnyPublisher()
        case .failure(let error):
            return Fail(error: .init(error)).eraseToAnyPublisher()
        }
    }
}

extension OpenBanking.Payment {

    public func get(in banking: OpenBankingClient) -> AnyPublisher<Details, OpenBanking.Error> {

        let request = banking.requestBuilder.get(
            path: ["payments", "payment", id.value],
            authenticated: true
        )

        return banking.network.perform(request: request, responseType: OpenBanking.Payment.Details.self)
            .handleEvents(receiveOutput: { [banking] details in
                guard let url = details.extraAttributes?.authorisationUrl else { return }
                banking.state.set(.authorisation.url, to: url)
            })
            .mapError(OpenBanking.Error.init)
            .eraseToAnyPublisher()
    }

    public func poll(in banking: OpenBankingClient) -> AnyPublisher<Details, OpenBanking.Error> {
        Deferred {
            get(in: banking)
        }
        .poll(
            max: 60,
            until: { payment in
                guard payment.extraAttributes?.error == nil else { return true }
                return payment.extraAttributes?.authorisationUrl != nil
            },
            delay: .seconds(2),
            scheduler: banking.scheduler
        )
        .mapError(OpenBanking.Error.init)
        .eraseToAnyPublisher()
    }
}

extension OpenBanking.Order {

    public func get(in banking: OpenBankingClient) -> AnyPublisher<OpenBanking.Order, OpenBanking.Error> {

        let request = banking.requestBuilder.get(
            path: ["simple-buy", "trades", id.value],
            authenticated: true
        )

        return banking.network.perform(request: request, responseType: OpenBanking.Order.self)
            .handleEvents(receiveOutput: { [banking] order in
                banking.state.transaction { state in
                    if let url = order.attributes?.authorisationUrl, let callback = order.attributes?.callbackPath {
                        state.set(.authorisation.url, to: url)
                        state.set(.callback.path, to: callback.dropPrefix("nabu-gateway").string)
                    }
                }
            })
            .mapError(OpenBanking.Error.init)
            .eraseToAnyPublisher()
    }

    public func poll(in banking: OpenBankingClient) -> AnyPublisher<OpenBanking.Order, OpenBanking.Error> {
        Deferred {
            get(in: banking)
        }
        .poll(
            max: 60,
            until: { payment in
                payment.attributes?.authorisationUrl != nil
            },
            delay: .seconds(2),
            scheduler: banking.scheduler
        )
        .mapError(OpenBanking.Error.init)
        .eraseToAnyPublisher()
    }
}

extension OpenBankingClient: OpenBankingClientAPI {

    public func activate(
        bankAccount: OpenBanking.BankAccount,
        with institution: Identity<OpenBanking.Institution>
    ) -> AnyPublisher<OpenBanking.BankAccount, OpenBanking.Error> {
        bankAccount.activateBankAccount(with: institution, in: self)
    }

    public func deposit(
        amountMinor: String,
        product: String,
        from account: OpenBanking.BankAccount
    ) -> AnyPublisher<OpenBanking.Payment, OpenBanking.Error> {
        account.deposit(amountMinor: amountMinor, product: product, in: self)
    }

    public func get(
        account: OpenBanking.BankAccount
    ) -> AnyPublisher<OpenBanking.BankAccount, OpenBanking.Error> {
        account.get(in: self)
    }

    public func poll(
        account: OpenBanking.BankAccount,
        until condition: @escaping (OpenBanking.BankAccount) -> Bool
    ) -> AnyPublisher<OpenBanking.BankAccount, OpenBanking.Error> {
        account.poll(in: self, until: condition)
    }

    public func get(
        payment: OpenBanking.Payment
    ) -> AnyPublisher<OpenBanking.Payment.Details, OpenBanking.Error> {
        payment.get(in: self)
    }

    public func poll(
        payment: OpenBanking.Payment
    ) -> AnyPublisher<OpenBanking.Payment.Details, OpenBanking.Error> {
        payment.poll(in: self)
    }

    public func get(
        order: OpenBanking.Order
    ) -> AnyPublisher<OpenBanking.Order, OpenBanking.Error> {
        order.get(in: self)
    }

    public func poll(
        order: OpenBanking.Order
    ) -> AnyPublisher<OpenBanking.Order, OpenBanking.Error> {
        order.poll(in: self)
    }
}
