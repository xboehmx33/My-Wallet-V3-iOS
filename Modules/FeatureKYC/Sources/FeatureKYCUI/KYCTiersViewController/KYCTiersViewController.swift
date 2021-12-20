// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import AnalyticsKit
import BigInt
import DIKit
import Foundation
import Localization
import MoneyKit
import PlatformKit
import PlatformUIKit
import RxSwift
import SafariServices
import ToolKit
import UIKit

protocol KYCTiersInterface: AnyObject {
    func apply(_ model: KYCTiersPageModel)
    func loadingIndicator(_ visibility: Visibility)
    func collectionViewVisibility(_ visibility: Visibility)
}

public final class KYCTiersViewController: UIViewController {

    // MARK: Private IBOutlets

    fileprivate var layout: UICollectionViewFlowLayout!
    fileprivate var collectionView: UICollectionView!

    // MARK: Private Properties

    fileprivate let drawerRouting: DrawerRouting = resolve()
    fileprivate var layoutAttributes: LayoutAttributes = .tiersOverview
    fileprivate var coordinator: KYCTiersCoordinator!
    private let loadingViewPresenter: LoadingViewPresenting = resolve()
    private let analyticsRecorder: AnalyticsEventRecorderAPI = resolve()
    fileprivate var disposable: Disposable?

    // MARK: Public Properties

    private var pageModel: KYCTiersPageModel
    public var selectedTier: ((KYC.Tier) -> Void)?
    public let parentFlow: KYCParentFlow

    public init(
        pageModel: KYCTiersPageModel,
        parentFlow: KYCParentFlow,
        title: String = LocalizationConstants.KYC.accountLimits
    ) {
        self.pageModel = pageModel
        self.parentFlow = parentFlow
        super.init(nibName: nil, bundle: nil)
        self.title = title
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        unimplemented()
    }

    // MARK: Lifecycle

    deinit {
        NotificationCenter.default.removeObserver(self)
        disposable?.dispose()
        disposable = nil
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        layout = UICollectionViewFlowLayout()
        collectionView = UICollectionView(frame: view.frame, collectionViewLayout: layout)
        view.addSubview(collectionView)
        collectionView.layoutToSuperview(.leading, .trailing, .bottom, .top)
        coordinator = KYCTiersCoordinator(interface: self)
        setupLayout()
        registerCells()
        registerSupplementaryViews()
        registerForNotifications()
        collectionView.reloadData()
        pageModel.trackPresentation(analyticsRecorder: analyticsRecorder)
        let backgroundColor = #colorLiteral(red: 0.9607843137, green: 0.968627451, blue: 0.9764705882, alpha: 1)
        collectionView.backgroundColor = backgroundColor
        view.backgroundColor = backgroundColor
    }

    fileprivate func setupLayout() {
        guard let layout = layout else { return }

        layout.sectionInset = layoutAttributes.sectionInsets
        layout.minimumLineSpacing = layoutAttributes.minimumLineSpacing
        layout.minimumInteritemSpacing = layoutAttributes.minimumInterItemSpacing
    }

    fileprivate func registerCells() {
        guard let collection = collectionView else { return }
        collection.delegate = self
        collection.dataSource = self
        collection.registerNibCell(KYCTierCell.self, in: .module)
    }

    fileprivate func registerSupplementaryViews() {
        guard let collection = collectionView else { return }
        let footer = UINib(nibName: KYCTiersFooterView.identifier, bundle: .featureKYCUI)
        collection.register(
            footer,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
            withReuseIdentifier: KYCTiersFooterView.identifier
        )
    }

    fileprivate func registerForNotifications() {
        NotificationCenter.when(Constants.NotificationKeys.kycFinished) { [weak self] _ in
            guard let this = self else { return }
            this.coordinator.refreshViewModel(
                suppressCTA: this.pageModel.header.suppressDismissCTA
            )
        }
        NotificationCenter.when(Constants.NotificationKeys.kycStopped) { [weak self] _ in
            guard let this = self else { return }
            this.coordinator.refreshViewModel(
                suppressCTA: this.pageModel.header.suppressDismissCTA
            )
        }
    }
}

extension KYCTiersViewController: KYCTiersHeaderViewDelegate {
    func headerView(_ view: KYCTiersHeaderView, actionTapped: KYCTiersHeaderViewModel.Action) {
        switch actionTapped {
        case .contactSupport:
            guard let supportURL = URL(string: Constants.Url.blockchainSupportRequest) else { return }
            let controller = SFSafariViewController(url: supportURL)
            present(controller, animated: true, completion: nil)
        case .learnMore:
            guard let verificationURL = URL(string: Constants.Url.verificationRejectedURL) else { return }
            let controller = SFSafariViewController(url: verificationURL)
            present(controller, animated: true, completion: nil)
        }
    }

    func dismissButtonTapped(_ view: KYCTiersHeaderView) {
        dismiss(animated: true, completion: nil)
    }
}

extension KYCTiersViewController: UICollectionViewDataSource {

    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        pageModel.cells.count
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let item = pageModel.cells[indexPath.row]
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: KYCTierCell.identifier,
            for: indexPath
        ) as? KYCTierCell else {
            return UICollectionViewCell()
        }
        cell.delegate = self
        cell.configure(with: item)
        return cell
    }
}

extension KYCTiersViewController: UICollectionViewDelegate {

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = pageModel.cells[indexPath.row]
        guard let cell = collectionView.cellForItem(at: indexPath) as? KYCTierCell else { return }
        guard item.status == .none else {
            Logger.shared.debug(
                """
                Not presenting KYC.
                KYC should only be presented if the status is `.none` for \(item.tier.tierDescription).
                The status is: \(item.status)
                """
            )
            return
        }
        if item.tier == .tier1 {
            analyticsRecorder.record(event: AnalyticsEvents.KYC.kycUnlockSilverClick)
        } else if item.tier == .tier2 {
            analyticsRecorder.record(event: AnalyticsEvents.KYC.kycUnlockGoldClick)
        }
        tierCell(cell, selectedTier: item.tier)
    }
}

extension KYCTiersViewController: UICollectionViewDelegateFlowLayout {
    public func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let model = pageModel.cells[indexPath.row]
        let widthInsets = layoutAttributes.sectionInsets.left - layoutAttributes.sectionInsets.right
        let width = collectionView.bounds.size.width - widthInsets
        let height = KYCTierCell.heightForProposedWidth(width, model: model)
        return CGSize(width: width, height: height)
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,

        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        switch kind {
        case UICollectionView.elementKindSectionFooter:
            guard let disclaimer = pageModel.disclaimer else { return UICollectionReusableView() }
            guard let footer = collectionView.dequeueReusableSupplementaryView(
                ofKind: UICollectionView.elementKindSectionFooter,
                withReuseIdentifier: KYCTiersFooterView.identifier,
                for: indexPath
            ) as? KYCTiersFooterView else { return UICollectionReusableView() }
            let ctaTitle = LocalizationConstants.ObjCStrings.BC_STRING_LEARN_MORE
            let trigger = ActionableTrigger(text: disclaimer, CTA: ctaTitle) { [weak self] in
                guard let strongSelf = self else { return }
                guard let supportURL = URL(string: Constants.Url.airdropProgram) else { return }
                let controller = SFSafariViewController(url: supportURL)
                strongSelf.present(controller, animated: true, completion: nil)
            }
            footer.configure(with: trigger)
            return footer
        default:
            return UICollectionReusableView()
        }
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForFooterInSection section: Int
    ) -> CGSize {
        guard let disclaimer = pageModel.disclaimer else { return .zero }
        let height = KYCTiersFooterView.estimatedHeight(
            for: disclaimer,
            width: collectionView.bounds.width
        )
        let width =
            collectionView.bounds.size.width
                - layoutAttributes.sectionInsets.left
                - layoutAttributes.sectionInsets.right

        return CGSize(width: width, height: height)
    }
}

extension KYCTiersViewController: KYCTierCellDelegate {
    func tierCell(_ cell: KYCTierCell, selectedTier: KYC.Tier) {
        // When a user is selecting a tier from `Swap` (which only happens
        // when the user isn't KYC approved) we want to present KYC from the applications
        // rootViewController rather than from `self`.
        if let block = self.selectedTier {
            block(selectedTier)
        } else {
            let kycRouter: KYCRouterAPI = resolve()
            guard let viewController = UIApplication.shared.topMostViewController else { return }
            kycRouter.start(tier: selectedTier, parentFlow: parentFlow, from: viewController)
        }
    }
}

extension KYCTiersViewController: KYCTiersInterface {
    func apply(_ newModel: KYCTiersPageModel) {
        pageModel = newModel
        registerSupplementaryViews()
        collectionView.reloadData()
        pageModel.trackPresentation(analyticsRecorder: analyticsRecorder)
    }

    func collectionViewVisibility(_ visibility: Visibility) {
        collectionView.alpha = visibility.defaultAlpha
    }

    func loadingIndicator(_ visibility: Visibility) {
        switch visibility {
        case .visible:
            loadingViewPresenter.show(with: LocalizationConstants.loading)
        case .hidden:
            loadingViewPresenter.hide()
        }
    }
}

extension KYCTiersViewController {

    private static func tiersPageModel(
        tiersService: KYCTiersServiceAPI = resolve()
    ) -> Single<KYCTiersPageModel> {
        // NOTE: currency hardcoded for now (IOS-5581), but it will be fixed in upcoming limits revamp work.
        tiersService.tiers
            .map { tiers -> (FiatValue, KYC.UserTiers) in
                guard tiers.tierAccountStatus(for: .tier1).isApproved else {
                    return (.zero(currency: .USD), tiers)
                }
                let latestApprovedTier = tiers.tiers.first(where: { $0.tier == tiers.latestApprovedTier })
                let maxTradableToday = FiatValue.create(
                    major: latestApprovedTier?.limits?.daily ?? 0,
                    currency: .USD
                )
                return (maxTradableToday, tiers)
            }
            .map { maxTradableToday, tiers -> KYCTiersPageModel in
                KYCTiersPageModel.make(tiers: tiers, maxTradableToday: maxTradableToday, suppressCTA: true)
            }
            .asSingle()
    }

    public static func routeToTiers(
        fromViewController: UIViewController
    ) -> Disposable {
        tiersPageModel()
            .observeOn(MainScheduler.instance)
            .subscribe(onSuccess: { model in
                let controller = KYCTiersViewController(pageModel: model, parentFlow: .settings)
                if let from = fromViewController as? UINavigationController {
                    from.pushViewController(controller, animated: true)
                    return
                }

                if let from = fromViewController as? UIViewControllerTransitioningDelegate {
                    controller.transitioningDelegate = from
                }
                if let navController = fromViewController.navigationController {
                    navController.pushViewController(controller, animated: true)
                } else {
                    let navController = NavigationController(rootViewController: controller)
                    navController.modalPresentationStyle = .fullScreen
                    fromViewController.present(navController, animated: true, completion: nil)
                }
            })
    }
}
