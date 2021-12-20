// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import CasePaths
import Combine
import Foundation

extension Publisher where Failure == Never {

    public func sink<Root>(
        to handler: @escaping (Root) -> (Output) -> Void,
        on root: Root
    ) -> AnyCancellable where Root: AnyObject {
        sink { [weak root] value in
            guard let root = root else { return }
            handler(root)(value)
        }
    }

    public func sink<Root>(
        to handler: @escaping (Root) -> () -> Void,
        on root: Root
    ) -> AnyCancellable where Root: AnyObject {
        sink { [weak root] _ in
            guard let root = root else { return }
            handler(root)()
        }
    }
}

extension Publisher {

    public func sink(
        receiveValue: @escaping (Output) -> Void
    ) -> AnyCancellable {
        sink { _ in } receiveValue: { output in
            receiveValue(output)
        }
    }

    public func sink<Root>(
        to handler: @escaping (Root) -> (Output) -> Void,
        on root: Root
    ) -> AnyCancellable where Root: AnyObject {
        sink { _ in } receiveValue: { [weak root] output in
            guard let root = root else { return }
            handler(root)(output)
        }
    }

    public func sink<Root>(
        to handler: @escaping (Root) -> () -> Void,
        on root: Root
    ) -> AnyCancellable where Root: AnyObject {
        sink { _ in } receiveValue: { [weak root] _ in
            guard let root = root else { return }
            handler(root)()
        }
    }

    public func sink<Root>(
        completion completionHandler: @escaping (Root) -> (Subscribers.Completion<Failure>) -> Void,
        receiveValue receiveValueHandler: @escaping (Root) -> (Output) -> Void,
        on root: Root
    ) -> AnyCancellable where Root: AnyObject {
        sink { [weak root] completion in
            guard let root = root else { return }
            completionHandler(root)(completion)
        } receiveValue: { [weak root] output in
            guard let root = root else { return }
            receiveValueHandler(root)(output)
        }
    }
}

extension Publisher {

    public func ignoreOutput<NewOutput>(
        setOutputType newOutputType: NewOutput.Type = NewOutput.self
    ) -> Publishers.Map<Publishers.IgnoreOutput<Self>, NewOutput> {
        ignoreOutput().map { _ -> NewOutput in }
    }

    public func ignoreFailure<NewFailure: Error>(
        setFailureType failureType: NewFailure.Type = NewFailure.self
    ) -> AnyPublisher<Output, NewFailure> {
        `catch` { _ in Empty() }
            .setFailureType(to: failureType)
            .eraseToAnyPublisher()
    }

    public func result() -> AnyPublisher<Result<Output, Failure>, Never> {
        map(Result.success).catch(Result.failure).eraseToAnyPublisher()
    }

    public func `catch`(_ handler: @escaping (Failure) -> Output) -> Publishers.Catch<Self, Just<Output>> {
        `catch` { error in Just(handler(error)) }
    }

    public func `catch`(_ output: @autoclosure @escaping () -> Output) -> Publishers.Catch<Self, Just<Output>> {
        `catch` { _ in Just(output()) }
    }
}

public protocol ExpressibleByError {
    init<E: Error>(_ error: E)
}

extension Publisher where Output: ResultProtocol {

    public func flatMap<P>(
        maxPublishers: Subscribers.Demand = .unlimited,
        _ transform: @escaping (Output.Success) throws -> P
    ) -> Publishers.FlatMap<AnyPublisher<P.Output, P.Failure>, Self> where
        P: Publisher,
        P.Output: ResultProtocol,
        P.Output.Failure: ExpressibleByError,
        P.Failure == Never
    {
        flatMap(maxPublishers: maxPublishers) { output in
            do {
                switch output.result {
                case .success(let success):
                    return try transform(success).eraseToAnyPublisher()
                case .failure(let error):
                    throw error
                }
            } catch {
                return Just(.failure(.init(error))).eraseToAnyPublisher()
            }
        }
    }
}

extension Publisher {

    /// Share the last known value of the stream to new subscribers
    public func shareReplay() -> AnyPublisher<Output, Failure> {
        let subject = CurrentValueSubject<Output?, Failure>(nil)
        return map { $0 }
            .multicast(subject: subject)
            .autoconnect()
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }
}

extension Publisher {

    /// Also provide the last value from another publisher
    public func withLatestFrom<Other: Publisher>(
        _ publisher: Other
    ) -> AnyPublisher<Other.Output, Failure> where Other.Failure == Failure {
        withLatestFrom(publisher, selector: { $1 })
    }

    /// Also provide the last value from another publisher. Allowing you to decide which publisher to select.
    public func withLatestFrom<Other: Publisher, Result>(
        _ other: Other,
        selector: @escaping (Output, Other.Output) -> Result
    ) -> AnyPublisher<Result, Failure> where Other.Failure == Failure {
        let upstream = share()
        return other
            .map { second in upstream.map { selector($0, second) } }
            .switchToLatest()
            .zip(upstream)
            .map(\.0)
            .eraseToAnyPublisher()
    }
}

extension Publisher {

    public func scan() -> AnyPublisher<(newValue: Output, oldValue: Output), Failure> {
        scan(count: 2)
            .map { ($0[1], $0[0]) }
            .eraseToAnyPublisher()
    }

    public func scan(count: Int) -> AnyPublisher<[Output], Failure> {
        scan([]) { ($0 + [$1]).suffix(count) }
            .filter { $0.count == count }
            .eraseToAnyPublisher()
    }
}

extension Publisher where Failure == Never {

    /// Assign the result of the stream to an property that wraps an Optional value
    public func assign<Root>(to keyPath: ReferenceWritableKeyPath<Root, Output?>, on root: Root) -> AnyCancellable {
        map(Output?.init).assign(to: keyPath, on: root)
    }
}

extension Publisher where Failure == Never {

    /// Assign the result of the stream to an published property that wraps an Optional value
    public func assign(to published: inout Published<Output?>.Publisher) {
        map(Output?.init).assign(to: &published)
    }
}

extension Publisher where Output: ResultProtocol {

    /// Ignore the `Result<Success, Failure>` failure case and map the `Success` to the streams output
    public func ignoreResultFailure() -> Publishers.CompactMap<Self, Output.Success> {
        compactMap { output in
            switch output.result {
            case .success(let o):
                return o
            case .failure:
                return nil
            }
        }
    }

    /// Ignore the stream output when it matches the CasePath `output`
    public func ignore<T>(output casePath: CasePath<Output.Success, T>) -> AnyPublisher<Output, Failure> {
        filter { output in
            switch output.result {
            case .failure:
                return true
            case .success(let success):
                return casePath.extract(from: success) != nil
            }
        }
        .eraseToAnyPublisher()
    }

    /// Ignore the stream failure when it matches the CasePath `failure`
    public func ignore<T>(failure casePath: CasePath<Output.Failure, T>) -> AnyPublisher<Output, Failure> {
        filter { output in
            switch output.result {
            case .failure(let error):
                return casePath.extract(from: error) != nil
            case .success:
                return true
            }
        }
        .eraseToAnyPublisher()
    }
}

extension Publisher where Output: ResultProtocol, Failure == Never {

    /// Converts a publisher which outputs a `Result` into a stream that can fail.
    public func get() -> AnyPublisher<Output.Success, Output.Failure> {
        flatMap { output -> AnyPublisher<Output.Success, Output.Failure> in
            switch output.result {
            case .failure(let error):
                return Fail(error: error).eraseToAnyPublisher()
            case .success(let success):
                return Just(success).setFailureType(to: Output.Failure.self).eraseToAnyPublisher()
            }
        }
        .eraseToAnyPublisher()
    }
}

extension Publisher {

    /// Filter using a KeyPath. Allowing usage of \.self syntax.
    public func filter(_ keyPath: KeyPath<Output, Bool>) -> Publishers.Filter<Self> {
        filter { $0[keyPath: keyPath] }
    }

    /// Find the first where the keyPath predicate is true. Allowing usage of \.self syntax.
    public func first(where keyPath: KeyPath<Output, Bool>) -> Publishers.FirstWhere<Self> {
        first { $0[keyPath: keyPath] }
    }
}

extension Publisher where Output == Bool, Failure == Never {

    /// Sink the result and make a decision using an if-else syntax
    public func `if`(
        then yes: @escaping () -> Void,
        else no: @escaping () -> Void
    ) -> AnyCancellable {
        sink { output in
            if output {
                yes()
            } else {
                no()
            }
        }
    }

    /// Sink the result and make a decision using an if-else syntax
    public func `if`<Root>(
        then yes: @escaping (Root) -> () -> Void,
        else no: @escaping (Root) -> () -> Void,
        on root: Root
    ) -> AnyCancellable where Root: AnyObject {
        sink { [weak root] output in
            guard let root = root else { return }
            if output {
                yes(root)()
            } else {
                no(root)()
            }
        }
    }
}

extension AnyCancellable {

    /// Store the lifetime of the cancellable against an Object.
    /// Once the object is deallocated the cancellable will go with it.
    public func store<Object>(
        withLifetimeOf object: Object,
        file: StaticString = #file,
        line: UInt = #line
    ) where Object: AnyObject {
        objc_setAssociatedObject(object, file.description + line.description, self, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}

extension Publisher {

    /// synonym for `map` using a CasePath
    public func map<T>(_ action: CasePath<T, Output>) -> Publishers.Map<Self, T> {
        map { output in action.embed(output) }
    }

    /// synonym for `map`
    @_disfavoredOverload
    public func map<T>(_ action: @autoclosure @escaping () -> T) -> Publishers.Map<Self, T> {
        map { _ -> T in action() }
    }
}

extension Publisher where Failure == Never {

    @inlinable public func assign<Root>(
        to keyPath: ReferenceWritableKeyPath<Root, Output>,
        on root: Root
    ) -> AnyCancellable where Root: AnyObject {
        sink { [weak root] in
            root?[keyPath: keyPath] = $0
        }
    }
}
