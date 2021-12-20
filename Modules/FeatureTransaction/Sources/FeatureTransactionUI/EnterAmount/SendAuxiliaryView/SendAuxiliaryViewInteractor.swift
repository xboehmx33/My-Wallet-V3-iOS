// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import DIKit
import MoneyKit
import PlatformKit
import PlatformUIKit
import RxCocoa
import RxSwift
import ToolKit

final class SendAuxiliaryViewInteractor: SendAuxiliaryViewInteractorAPI {

    private let contentLabelViewInteractor = ContentLabelViewInteractor()
    private let networkLabelViewInteractor = ContentLabelViewInteractor()

    let resetToMaxAmountRelay = PublishRelay<Void>()
    let networkFeeTappedRelay = PublishRelay<Void>()
    let availableBalanceTappedRelay = PublishRelay<Void>()
    let imageRelay = PublishRelay<ImageViewContent>()

    var networkFeeContentViewInteractor: ContentLabelViewInteractorAPI {
        networkLabelViewInteractor
    }

    var availableBalanceContentViewInteractor: ContentLabelViewInteractorAPI {
        contentLabelViewInteractor
    }

    func connect(stream: Observable<MoneyValue>) -> Disposable {
        stream
            .map { $0.toDisplayString(includeSymbol: true) }
            .map { ValueCalculationState.value($0) }
            .bindAndCatch(to: contentLabelViewInteractor.stateSubject)
    }

    func connect(fee: Observable<MoneyValue>) -> Disposable {
        fee
            .map { $0.toDisplayString(includeSymbol: true) }
            .map { ValueCalculationState.value($0) }
            .bindAndCatch(to: networkLabelViewInteractor.stateSubject)
    }
}

final class ContentLabelViewInteractor: ContentLabelViewInteractorAPI {

    var contentCalculationState: Observable<ValueCalculationState<String>> {
        stateSubject.asObservable()
    }

    let stateSubject: BehaviorSubject<ValueCalculationState<String>> = .init(value: .calculating)
}
