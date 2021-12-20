// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import Foundation

/// A generic value fetcher, interacting with local and remote data sources.
///
/// - Key:   A cache key, used to store values in the local data source, and to fetch values from the remote data source.
/// - Value: A cache value.
public final class CachedValueNew<Key: Hashable, Value: Equatable, CacheError: Error> {

    // MARK: - Private Properties

    private let cache: AnyCache<Key, Value>

    private let fetch: (Key) -> AnyPublisher<Value, CacheError>

    private let inFlightRequests = Atomic<[Key: AnyPublisher<Value, CacheError>]>([:])

    private let queue = DispatchQueue(label: "com.blockchain.cached-value-new.queue")

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Setup

    /// Creates a CachedValueNew.
    ///
    /// - Parameters:
    ///   - cache: A cache.
    ///   - fetch: A fetch function.
    public init(
        cache: AnyCache<Key, Value>,
        fetch: @escaping (Key) -> AnyPublisher<Value, CacheError>
    ) {
        self.cache = cache
        self.fetch = fetch
    }

    // MARK: - Public Methods

    /// Gets the value associated with the given key, optionally ignoring values in the local data source.
    ///
    /// If the value is in the local data source, is not stale, and `forceFetch` is set to false, this value will be returned.
    /// Otherwise, the value will be fetched from the remote data source, and then stored in the local data source.
    ///
    /// - Parameters:
    ///   - key:        A key, used to store the value in the local data source, and to fetch the value from the remote data source.
    ///   - forceFetch: Whether values in the local data source should be ignored.
    ///
    /// - Returns: A publisher that emits the value on success, or a `CacheError` on failure.
    public func get(key: Key, forceFetch: Bool = false) -> AnyPublisher<Value, CacheError> {
        if forceFetch {
            return fetchAndStore(for: key)
        }

        return cache.get(key: key)
            .flatMap { [fetchAndStore] value -> AnyPublisher<Value, CacheError> in
                switch value {
                case .absent, .stale:
                    return fetchAndStore(key)
                case .present(let value):
                    return .just(value)
                }
            }
            .eraseToAnyPublisher()
    }

    public func invalidateCacheWithKey(_ key: Key) {
        cache
            .remove(key: key)
            .subscribe()
            .store(in: &cancellables)
    }

    /// Streams the value associated with the given key, including any subsequent updates, optionally skipping stale values in the local data source.
    ///
    /// If the value is in the local data source, but stale, and `skipStale` is set to false, this value will be streamed, but a remote data source request will be created to update it.
    /// Otherwise, the value will be fetched from the remote data source, and then stored in the local data source.
    ///
    /// - Parameters:
    ///   - key:       A key, used to store the value in the local data source, and to fetch the value from the remote data source.
    ///   - skipStale: Whether stale values in the local data source should be skipped.
    ///                This is useful when stale values are safe to be used, as it speeds up apparent loading times.
    ///
    /// - Returns: A publisher that streams the value or the error, including any subsequent updates.
    public func stream(key: Key, skipStale: Bool = false) -> StreamOf<Value, CacheError> {
        cache.stream(key: key)
            .flatMap { [fetchAndStore] value -> StreamOf<CacheValue<Value>, CacheError> in
                switch value {
                case .absent, .stale:
                    return fetchAndStore(key)
                        // Ignore output as `stream` will capture the update
                        .ignoreOutput(setOutputType: Result<CacheValue<Value>, CacheError>.self)
                        // Map error to `Result.failure`
                        .catch { Just(.failure($0)) }
                        // Return current output as some consumers may use stale values
                        .merge(with: Just(.success(value)))
                        .eraseToAnyPublisher()
                case .present:
                    return .just(.success(value))
                }
            }
            .compactMap { result in
                switch result {
                case .failure(let error):
                    return .failure(error)
                case .success(.absent):
                    return nil
                case .success(.stale(let value)):
                    return skipStale ? nil : .success(value)
                case .success(.present(let value)):
                    return .success(value)
                }
            }
            .eraseToAnyPublisher()
    }

    // MARK: - Private Methods

    /// Fetches the value associated with the given key from the remote data source, and stores it in the local data source.
    ///
    /// Keeps track of existing in-flight requests, in order to avoid creating duplicate requests.
    ///
    /// - Parameter key: A key, used to store the value in the local data source, and to fetch the value from the remote data source.
    ///
    /// - Returns: A publisher that emits the fetched value on success, or a `CacheError` on failure.
    private func fetchAndStore(for key: Key) -> AnyPublisher<Value, CacheError> {
        inFlightRequests.mutateAndReturn { requests -> AnyPublisher<Value, CacheError> in
            if let request = requests[key] {
                // There is a request in-flight.
                return request
            }

            // There is no request in-flight, create a new request.
            let request = createRemoteRequest(for: key)
                .handleEvents(
                    receiveOutput: { [weak inFlightRequests] _ in
                        // Remove from in-flight requests, after it receives a value.
                        inFlightRequests?.mutate { $0[key] = nil }
                    },
                    receiveCompletion: { [weak inFlightRequests] _ in
                        // Remove from in-flight requests, after it completed.
                        inFlightRequests?.mutate { $0[key] = nil }
                    }
                )
                .subscribe(on: queue)
                .share()
                .eraseToAnyPublisher()

            // Add to in-flight requests.
            requests[key] = request

            return request
        }
    }

    /// Creates a remote data source request for the value associated with given key.
    ///
    /// - Parameter key: A key, used as the remote request parameter.
    ///
    /// - Returns: A publisher that emits the fetched value on success, or a `CacheError` on failure.
    private func createRemoteRequest(for key: Key) -> AnyPublisher<Value, CacheError> {
        fetch(key)
            .flatMap { [cache] value in
                cache.set(value, for: key)
                    .map { _ in value }
            }
            .eraseToAnyPublisher()
    }
}
