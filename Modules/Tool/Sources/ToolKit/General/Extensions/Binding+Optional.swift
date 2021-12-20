// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import SwiftUI

extension Binding where Value: Equatable {

    @inlinable public func equals(_ value: Value, default defaultValue: Value) -> Binding<Bool> {
        .init(
            get: { wrappedValue == value },
            set: { newValue in transaction(transaction).wrappedValue = newValue ? value : defaultValue }
        )
    }
}

extension Binding where Value: Equatable, Value: OptionalProtocol {

    @inlinable public func equals(_ value: Value, default defaultValue: Value = nil) -> Binding<Bool> {
        .init(
            get: { wrappedValue == value },
            set: { newValue in transaction(transaction).wrappedValue = newValue ? value : defaultValue }
        )
    }

    @inlinable public func `if`(_ condition: @escaping (Value.Wrapped) -> Bool, default defaultValue: Bool = false) -> Binding<Bool> {
        Binding<Bool>(
            get: { wrappedValue.wrapped.map(condition) ?? defaultValue },
            set: { newValue in
                guard !newValue else { return }
                transaction(transaction).wrappedValue = nil
            }
        )
    }
}

extension Binding {

    @inlinable public subscript<T>(keyPath: WritableKeyPath<Value, T>) -> Binding<T> {
        .init(
            get: { wrappedValue[keyPath: keyPath] },
            set: { transaction(transaction).wrappedValue[keyPath: keyPath] = $0 }
        )
    }
}

extension Binding where Value == Bool {

    @inlinable public func inverted() -> Binding {
        .init(
            get: { !wrappedValue },
            set: { transaction(transaction).wrappedValue = !$0 }
        )
    }
}

extension Binding {

    @inlinable public subscript() -> DynamicMemberLookup {
        .init(self)
    }

    @dynamicMemberLookup
    public struct DynamicMemberLookup {

        @usableFromInline let _binding: Binding

        @inlinable public init(_ binding: Binding) {
            _binding = binding
        }

        @inlinable public subscript<T>(dynamicMember keyPath: WritableKeyPath<Value, T>) -> Binding<T>.DynamicMemberLookup {
            .init(_binding[keyPath])
        }

        @inlinable public func binding() -> Binding { _binding }
    }
}
