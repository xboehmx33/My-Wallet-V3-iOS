// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import EthereumKit
import NetworkError
import ToolKit

/// An ERC-20 token accounts repository error.
public enum ERC20TokenAccountsError: Error, Equatable, CustomStringConvertible {

    /// Network error.
    case network(NetworkError)

    // MARK: - Public Properties

    public var description: String {
        switch self {
        case .network(let error):
            return "network(\(error))"
        }
    }
}

/// A repository in charge of getting ERC-20 token accounts associated with a given ethereum account address.
public protocol ERC20TokenAccountsRepositoryAPI {

    /// Invalidates the `ERC20TokenAccounts` cache. This is used after a
    /// transaction completes to ensure views show the latest balance.
    ///
    /// - Parameter address: The ethereum account address.
    func invalidateERC20TokenAccountsForAddress(_ address: EthereumAddress)

    /// Gets the ERC-20 token accounts associated with the given ethereum account address, optionally ignoring cached values.
    ///
    /// - Parameters:
    ///   - address:    The ethereum account address to get the ERC-20 token accounts for.
    ///   - forceFetch: Whether the cached values should be ignored.
    ///
    /// - Returns: A publisher that emits a `ERC20TokenAccounts` on success, or a `ERC20TokenAccountsError` on failure.
    func tokens(
        for address: EthereumAddress,
        forceFetch: Bool
    ) -> AnyPublisher<ERC20TokenAccounts, ERC20TokenAccountsError>

    /// Streams the ERC-20 token accounts associated with the given ethereum account address, including any subsequent updates, optionally ignoring cached values.
    ///
    /// - Parameters:
    ///   - address:   The ethereum account address to get the ERC-20 token accounts for.
    ///   - skipStale: Whether stale values in the local data source should be skipped.
    ///                This is useful when stale values are safe to be used, as it speeds up apparent loading times.
    ///
    /// - Returns: A publisher that streams a `ERC20TokenAccounts` or `ERC20TokenAccountsError`, including any subsequent updates.
    func tokensStream(
        for address: EthereumAddress,
        skipStale: Bool
    ) -> StreamOf<ERC20TokenAccounts, ERC20TokenAccountsError>
}

extension ERC20TokenAccountsRepositoryAPI {

    /// Gets the ERC-20 token accounts associated with the given ethereum account address.
    ///
    /// - Parameter address: The ethereum account address to get the ERC-20 token accounts for.
    ///
    /// - Returns: A publisher that emits a `ERC20TokenAccounts` on success, or a `ERC20TokenAccountsError` on failure.
    public func tokens(
        for address: EthereumAddress
    ) -> AnyPublisher<ERC20TokenAccounts, ERC20TokenAccountsError> {
        tokens(for: address, forceFetch: false)
    }

    /// Streams the ERC-20 token accounts associated with the given ethereum account address, including any subsequent updates.
    ///
    /// - Parameter address: The ethereum account address to get the ERC-20 token accounts for.
    ///
    /// - Returns: A publisher that streams a `ERC20TokenAccounts` or `ERC20TokenAccountsError`, including any subsequent updates.
    public func tokensStream(
        for address: EthereumAddress
    ) -> StreamOf<ERC20TokenAccounts, ERC20TokenAccountsError> {
        tokensStream(for: address, skipStale: false)
    }
}
