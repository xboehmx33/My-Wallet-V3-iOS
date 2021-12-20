// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import MoneyKit
import PlatformKit
import RxCocoa
import RxRelay
import RxSwift

public final class AssetSparklinePresenter {

    // MARK: - Public Properties

    public var lineColor: UIColor {
        interactor.cryptoCurrency.brandUIColor
    }

    public var state: Observable<State> {
        stateRelay.asObservable()
    }

    // MARK: - Private Properties

    private let stateRelay = BehaviorRelay<State>(value: .empty)
    private let disposeBag = DisposeBag()

    // MARK: - Injected

    private let interactor: SparklineInteracting

    public init(with interactor: SparklineInteracting) {
        self.interactor = interactor

        self.interactor.calculationState
            .map(weak: self) { _, calculationState -> State in
                switch calculationState {
                case .calculating:
                    return .loading
                case .invalid:
                    return .invalid
                case .value(let value):
                    return .valid(prices: value)
                }
            }
            .bindAndCatch(to: stateRelay)
            .disposed(by: disposeBag)
    }
}

extension AssetSparklinePresenter {

    public enum State {
        /// There is no data to display
        case empty

        /// The data is being fetched
        case loading

        /// Valid state - data has been received
        case valid(prices: [Decimal])

        /// Invalid state - An error was thrown
        case invalid

        /// Returns the text value if there is a valid value
        public var value: [Decimal]? {
            switch self {
            case .valid(let value):
                return value
            default:
                return nil
            }
        }
    }
}
