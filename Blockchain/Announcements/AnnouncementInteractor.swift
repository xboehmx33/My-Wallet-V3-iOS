// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import DIKit
import ERC20Kit
import FeatureAuthenticationDomain
import MoneyKit
import PlatformKit
import PlatformUIKit
import RxSwift
import RxToolKit
import ToolKit

/// The announcement interactor cross all the preliminary data
/// that is required to display announcements to the user
final class AnnouncementInteractor: AnnouncementInteracting {

    // MARK: - Services

    /// Returns announcement preliminary data, according to which the relevant
    /// announcement will be displayed
    var preliminaryData: Single<AnnouncementPreliminaryData> {
        guard wallet.isInitialized() else {
            return Single.error(AnnouncementError.uninitializedWallet)
        }

        let assetRenameAnnouncement: Single<AssetRenameAnnouncementFeature> = featureFetcher
            .fetch(for: .assetRenameAnnouncement)
        let assetRename: Single<AnnouncementPreliminaryData.AssetRename?> = assetRenameAnnouncement
            .flatMap { [enabledCurrenciesService, coincore] data -> Single<AnnouncementPreliminaryData.AssetRename?> in
                guard let cryptoCurrency = CryptoCurrency(
                    code: data.networkTicker,
                    enabledCurrenciesService: enabledCurrenciesService
                ) else {
                    return .just(nil)
                }
                return coincore[cryptoCurrency]
                    .accountGroup(filter: .all)
                    .asSingle()
                    .flatMap(\.balance)
                    .map { balance in
                        AnnouncementPreliminaryData.AssetRename(
                            asset: cryptoCurrency,
                            oldTicker: data.oldTicker,
                            balance: balance
                        )
                    }
            }
            .catchAndReturn(nil)

        let hasLinkedBanks = beneficiariesService.hasLinkedBank
            .take(1)
            .asSingle()
        let isSimpleBuyAvailable = supportedPairsInteractor.pairs
            .map { !$0.pairs.isEmpty }
            .take(1)
            .asSingle()
        let isSimpleBuyEligible = simpleBuyEligibilityService.isEligible
        let simpleBuyOrderDetails = pendingOrderDetailsService.pendingActionOrderDetails

        let simpleBuy: Single<AnnouncementPreliminaryData.SimpleBuy> = Single
            .zip(
                hasLinkedBanks,
                isSimpleBuyAvailable,
                isSimpleBuyEligible,
                simpleBuyOrderDetails
            )
            .map { hasLinkedBanks, isSimpleBuyAvailable, isSimpleBuyEligible, simpleBuyOrderDetails in
                AnnouncementPreliminaryData.SimpleBuy(
                    hasLinkedBanks: hasLinkedBanks,
                    isAvailable: isSimpleBuyAvailable,
                    isEligible: isSimpleBuyEligible,
                    pendingOrderDetails: simpleBuyOrderDetails
                )
            }

        let nabuUser = userService.user.asSingle()
        let tiers = tiersService.tiers.asSingle()
        let sddEligibility = tiersService.checkSimplifiedDueDiligenceEligibility()
            .asSingle()
        let countries = infoService.countries

        let hasAnyWalletBalance = coincore.allAccounts
            .asSingle()
            .map(\.accounts)
            .flatMap { accounts -> Single<[Bool]> in
                Single.zip(accounts.map { $0.isFunded.catchAndReturn(false) })
            }
            .map { values in
                values.contains(true)
            }

        let authenticatorType = repository.authenticatorType
        let newAsset: Single<CryptoCurrency?> = featureFetcher
            .fetchString(for: .newAssetAnnouncement)
            .map { [enabledCurrenciesService] code -> CryptoCurrency? in
                CryptoCurrency(
                    code: code,
                    enabledCurrenciesService: enabledCurrenciesService
                )
            }
            .catchAndReturn(nil)

        let celoEUR: CryptoCurrency? = enabledCurrenciesService
            .allEnabledCryptoCurrencies
            .first { cryptoCurrency in
                cryptoCurrency.isCeloToken
                    && cryptoCurrency.code.uppercased() == "CEUR"
            }

        return Single.zip(
            nabuUser,
            tiers,
            countries,
            authenticatorType.asSingle(),
            hasAnyWalletBalance,
            Single.zip(
                newAsset,
                assetRename,
                simpleBuy,
                sddEligibility
            )
        )
        .map { payload -> AnnouncementPreliminaryData in
            let (
                user,
                tiers,
                countries,
                authenticatorType,
                hasAnyWalletBalance,
                (
                    newAsset,
                    assetRename,
                    simpleBuy,
                    isSDDEligible
                )
            ) = payload
            return AnnouncementPreliminaryData(
                user: user,
                tiers: tiers,
                isSDDEligible: isSDDEligible,
                countries: countries,
                authenticatorType: authenticatorType,
                hasAnyWalletBalance: hasAnyWalletBalance,
                newAsset: newAsset,
                assetRename: assetRename,
                simpleBuy: simpleBuy,
                celoEUR: celoEUR
            )
        }
        .observe(on: MainScheduler.instance)
    }

    // MARK: - Private properties

    private let repository: AuthenticatorRepositoryAPI
    private let wallet: WalletProtocol
    private let userService: NabuUserServiceAPI
    private let tiersService: KYCTiersServiceAPI
    private let infoService: GeneralInformationServiceAPI
    private let supportedPairsInteractor: SupportedPairsInteractorServiceAPI
    private let beneficiariesService: BeneficiariesServiceAPI
    private let pendingOrderDetailsService: PendingOrderDetailsServiceAPI
    private let simpleBuyEligibilityService: EligibilityServiceAPI
    private let featureFetcher: RxFeatureFetching
    private let enabledCurrenciesService: EnabledCurrenciesServiceAPI
    private let coincore: CoincoreAPI

    // MARK: - Setup

    init(
        repository: AuthenticatorRepositoryAPI = resolve(),
        wallet: WalletProtocol = WalletManager.shared.wallet,
        userService: NabuUserServiceAPI = resolve(),
        tiersService: KYCTiersServiceAPI = resolve(),
        featureFetcher: RxFeatureFetching = resolve(),
        infoService: GeneralInformationServiceAPI = resolve(),
        supportedPairsInteractor: SupportedPairsInteractorServiceAPI = resolve(),
        beneficiariesService: BeneficiariesServiceAPI = resolve(),
        pendingOrderDetailsService: PendingOrderDetailsServiceAPI = resolve(),
        simpleBuyEligibilityService: EligibilityServiceAPI = resolve(),
        enabledCurrenciesService: EnabledCurrenciesServiceAPI = resolve(),
        coincore: CoincoreAPI = resolve()
    ) {
        self.repository = repository
        self.wallet = wallet
        self.userService = userService
        self.tiersService = tiersService
        self.infoService = infoService
        self.supportedPairsInteractor = supportedPairsInteractor
        self.beneficiariesService = beneficiariesService
        self.pendingOrderDetailsService = pendingOrderDetailsService
        self.simpleBuyEligibilityService = simpleBuyEligibilityService
        self.coincore = coincore
        self.featureFetcher = featureFetcher
        self.enabledCurrenciesService = enabledCurrenciesService
    }
}
