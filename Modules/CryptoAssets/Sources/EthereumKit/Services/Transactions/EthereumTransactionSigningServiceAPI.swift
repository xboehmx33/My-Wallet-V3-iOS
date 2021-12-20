// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BigInt
import Combine
import DIKit
import PlatformKit
import RxSwift

public enum EthereumTransactionSigningServiceError: TransactionValidationError {
    case failedAccountNonce(Error)
    case errorSigningTransaction(Error)
}

protocol EthereumTransactionSigningServiceAPI {
    func sign(
        transaction: EthereumTransactionCandidate,
        keyPair: EthereumKeyPair
    ) -> AnyPublisher<EthereumTransactionEncoded, EthereumTransactionSigningServiceError>
}

final class EthereumTransactionSigningService: EthereumTransactionSigningServiceAPI {

    private let accountDetailsService: EthereumAccountDetailsServiceAPI
    private let transactionSigner: EthereumSignerAPI

    init(
        accountDetailsService: EthereumAccountDetailsServiceAPI = resolve(),
        transactionSigner: EthereumSignerAPI = resolve()
    ) {
        self.accountDetailsService = accountDetailsService
        self.transactionSigner = transactionSigner
    }

    func sign(
        transaction: EthereumTransactionCandidate,
        keyPair: EthereumKeyPair
    ) -> AnyPublisher<EthereumTransactionEncoded, EthereumTransactionSigningServiceError> {
        defaultAccountNonce()
            .flatMap { [buildSign] nonce in
                buildSign(transaction, nonce, keyPair)
                    .publisher
            }
            .eraseToAnyPublisher()
    }

    private func buildSign(
        transaction: EthereumTransactionCandidate,
        nonce: UInt64,
        keyPair: EthereumKeyPair
    ) -> Result<EthereumTransactionEncoded, EthereumTransactionSigningServiceError> {
        EthereumTransactionCandidateCosted
            .create(transaction: transaction, nonce: BigUInt(nonce))
            .eraseError()
            .flatMap { costed in
                transactionSigner.sign(transaction: costed, keyPair: keyPair)
                    .eraseError()
            }
            .mapError(EthereumTransactionSigningServiceError.errorSigningTransaction)
    }

    private func defaultAccountNonce() -> AnyPublisher<UInt64, EthereumTransactionSigningServiceError> {
        accountDetailsService.accountDetails()
            .map(\.nonce)
            .asPublisher()
            .mapError(EthereumTransactionSigningServiceError.failedAccountNonce)
            .eraseToAnyPublisher()
    }
}
