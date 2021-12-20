// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import AnalyticsKit
import DIKit
import Localization
import MoneyKit
import PlatformKit
import PlatformUIKit
import RIBs
import RxCocoa
import RxSwift
import UIComponentsKit

protocol SwapLandingRouting: ViewableRouting {}

enum SwapLandingSelectionEffects {
    case swap(SwapTrendingPair)
    case newSwap
    case none
}

enum SwapLandingSelectionAction: Equatable {
    case items([SwapLandingSectionModel])
}

struct SwapLandingScreenState {
    let header: AccountPickerHeaderModel
    let action: SwapLandingSelectionAction
}

protocol SwapLandingPresentable: Presentable {
    var listener: SwapLandingPresentableListener? { get set }

    func connect(state: Driver<SwapLandingScreenState>) -> Driver<SwapLandingSelectionEffects>
}

protocol SwapLandingListener: AnyObject {
    func routeToSwap(with pair: SwapTrendingPair?)
}

final class SwapLandingInteractor: PresentableInteractor<SwapLandingPresentable>, SwapLandingInteractable, SwapLandingPresentableListener {

    typealias AnalyticsEvent = AnalyticsEvents.Swap
    typealias NewSwapAnalyticsEvent = AnalyticsEvents.New.Swap
    typealias LocalizationId = LocalizationConstants.Swap.Trending

    weak var router: SwapLandingRouting?
    weak var listener: SwapLandingListener?

    // MARK: - Private properties

    private var initialState: Observable<State> {
        let custodialAccounts = accountProviding
            .accounts(accountType: .custodial(.trading))
            .map { accounts in
                accounts.filter { $0 is CryptoAccount }
            }
            .map { $0.map { $0 as! CryptoAccount } }
            .catchErrorJustReturn([])

        let nonCustodialAccounts = accountProviding
            .accounts(accountType: .nonCustodial)
            .map { accounts in
                accounts.filter { $0 is CryptoAccount }
            }
            .map { $0.map { $0 as! CryptoAccount } }
            .catchErrorJustReturn([])

        return eligibilityService.isEligible
            .flatMap { $0 ? custodialAccounts : nonCustodialAccounts }
            .catchError { _ in nonCustodialAccounts }
            .map { [pax] accounts -> [SwapTrendingPairViewModel] in
                var pairs: [(CryptoCurrency, CryptoCurrency)] = [
                    (.coin(.bitcoin), .coin(.ethereum)),
                    (.coin(.bitcoin), pax),
                    (.coin(.bitcoin), .coin(.stellar))
                ]
                switch DevicePresenter.type {
                case .superCompact, .compact:
                    break
                case .regular:
                    pairs.append((.coin(.bitcoin), .coin(.bitcoinCash)))
                case .max:
                    pairs.append((.coin(.bitcoin), .coin(.bitcoinCash)))
                    pairs.append((.coin(.ethereum), pax))
                }
                return pairs
                    .compactMap { pair -> SwapTrendingPair? in
                        accounts.trendingPair(source: pair.0, destination: pair.1)
                    }
                    .map { trendingPair -> SwapTrendingPairViewModel in
                        SwapTrendingPairViewModel(trendingPair: trendingPair)
                    }
            }
            .map { .init(pairViewModels: $0) }
            .asObservable()
            .share(replay: 1, scope: .whileConnected)
    }

    private lazy var pax: CryptoCurrency = enabledCurrenciesService.allEnabledCryptoCurrencies
        .first(where: { $0.code == ERC20Code.pax.rawValue })!
    private let accountProviding: BlockchainAccountProviding
    private let eligibilityService: EligibilityServiceAPI
    private let analyticsRecorder: AnalyticsEventRecorderAPI
    private let enabledCurrenciesService: EnabledCurrenciesServiceAPI

    // MARK: - Init

    init(
        presenter: SwapLandingPresentable,
        accountProviding: BlockchainAccountProviding = resolve(),
        analyticsRecorder: AnalyticsEventRecorderAPI = resolve(),
        eligibilityService: EligibilityServiceAPI = resolve(),
        enabledCurrenciesService: EnabledCurrenciesServiceAPI = resolve()
    ) {
        self.accountProviding = accountProviding
        self.eligibilityService = eligibilityService
        self.enabledCurrenciesService = enabledCurrenciesService
        self.analyticsRecorder = analyticsRecorder
        super.init(presenter: presenter)
        presenter.listener = self
    }

    // MARK: - Internal methods

    override func didBecomeActive() {
        super.didBecomeActive()

        let items = initialState
            .map { state -> SwapLandingSectionModel in
                let pairs: [SwapLandingSectionItem] = state.pairViewModels.map { .pair($0) }
                let cells = Array(pairs.map { [$0] }.joined(separator: [.separator(index: .random(in: 1...Int.max))]))
                return .init(items: cells)
            }
            .map { SwapLandingSelectionAction.items([$0]) }
            // TODO: implement empty state for trending pairs:
            // TICKET: IOS-4268
            .catchErrorJustReturn(SwapLandingSelectionAction.items([]))
            .asDriverCatchError()

        let header = initialState
            .map(\.header)
            .asDriverCatchError()

        let model = Driver.zip(items, header)
            .map { SwapLandingScreenState(header: $0.1, action: $0.0) }

        let actions = Driver.merge(model)
        presenter.connect(state: actions)
            .drive(onNext: handleEffects)
            .disposeOnDeactivate(interactor: self)
    }

    override func willResignActive() {
        super.willResignActive()
    }

    func newSwap(withPair pair: SwapTrendingPair?) {
        listener?.routeToSwap(with: pair)
    }

    // MARK: - Private methods

    func handleEffects(_ effect: SwapLandingSelectionEffects) {
        switch effect {
        case .swap(let pair):
            analyticsRecorder.record(events: [
                AnalyticsEvent.trendingPairClicked,
                NewSwapAnalyticsEvent.swapAccountsSelected(
                    inputCurrency: pair.sourceAccount.currencyType.code,
                    inputType: .init(pair.sourceAccount),
                    outputCurrency: pair.destinationAccount.currencyType.code,
                    outputType: .init(pair.destinationAccount),
                    wasSuggested: true
                )
            ])
            listener?.routeToSwap(with: pair)
        case .newSwap:
            analyticsRecorder.record(event: AnalyticsEvent.newSwapClicked)
            listener?.routeToSwap(with: nil)
        case .none:
            break
        }
    }
}

extension SwapLandingInteractor {
    struct State {
        var header: AccountPickerHeaderModel = .init(
            imageContent: .init(
                imageResource: ImageAsset.iconSwapTransaction.imageResource,
                accessibility: .none,
                renderingMode: .normal
            ),
            subtitle: LocalizationId.Header.description,
            tableTitle: LocalizationId.trending,
            title: LocalizationId.Header.title
        )
        var pairViewModels: [SwapTrendingPairViewModel]
    }
}

extension Array where Element == CryptoAccount {
    func trendingPair(
        source sourceCurrency: CryptoCurrency,
        destination destinationCurrency: CryptoCurrency
    ) -> SwapTrendingPair? {
        guard let source = first(where: { $0.currencyType == sourceCurrency }) else {
            return nil
        }
        guard let destination = first(where: { $0.currencyType == destinationCurrency }) else {
            return nil
        }
        return SwapTrendingPair(
            sourceAccount: source,
            destinationAccount: destination,
            enabled: true
        )
    }
}
