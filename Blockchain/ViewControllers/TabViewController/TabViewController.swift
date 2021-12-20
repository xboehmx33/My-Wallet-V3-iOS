// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import FeatureAppUI
import FeatureSettingsDomain
import PlatformKit
import PlatformUIKit
import RxSwift
import ToolKit

@objc protocol TabViewControllerDelegate: AnyObject {

    func tabViewControllerViewDidLoad(_ tabViewController: TabViewController)
    func tabViewController(_ tabViewController: TabViewController, viewDidAppear animated: Bool)
    func transactionsClicked()
    func sendClicked()
    func receiveClicked()
    func dashBoardClicked()
    func swapClicked()
}

@objc final class TabViewController: UIViewController, UITabBarDelegate {

    // MARK: - Properties

    var sideMenuGesture: UIPanGestureRecognizer?

    @objc weak var delegate: TabViewControllerDelegate?
    private(set) var menuSwipeRecognizerView: UIView!
    private(set) var activeViewController: UIViewController?
    private(set) lazy var sheetPresenter = BottomSheetPresenting()

    // MARK: - Private IBOutlets

    @IBOutlet private var receiveTabBarItem: UITabBarItem!
    @IBOutlet private var sendTabBarItem: UITabBarItem!
    @IBOutlet private var homeTabBarItem: UITabBarItem!
    @IBOutlet private var activityTabBarItem: UITabBarItem!
    @IBOutlet private var swapTabBarItem: UITabBarItem!
    @IBOutlet private var contentView: UIView!
    @IBOutlet private var tabBar: UITabBar!

    // MARK: - Private Properties

    private var selectedIndex: Int = 0 {
        didSet {
            tabBar.selectedItem = nil
            let newSelectedIndex = selectedIndex
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) { [weak self] in
                guard let self = self else { return }
                self.tabBar.selectedItem = self.tabBar.items?[newSelectedIndex]
            }
        }
    }

    private var tabBarGestureView: UIView?
    private let disposeBag = DisposeBag()

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tabBar.delegate = self
        selectedIndex = Constants.Navigation.tabDashboard
        menuSwipeRecognizerView = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: UIScreen.main.bounds.size.height))
        if let panGesture = sideMenuGesture {
            menuSwipeRecognizerView.addGestureRecognizer(panGesture)
        }
        view.addSubview(menuSwipeRecognizerView)

        receiveTabBarItem.accessibility = .id(AccessibilityIdentifiers.TabViewContainerScreen.request)
        activityTabBarItem.accessibility = .id(AccessibilityIdentifiers.TabViewContainerScreen.activity)
        swapTabBarItem.accessibility = .id(AccessibilityIdentifiers.TabViewContainerScreen.swap)
        homeTabBarItem.accessibility = .id(AccessibilityIdentifiers.TabViewContainerScreen.home)
        sendTabBarItem.accessibility = .id(AccessibilityIdentifiers.TabViewContainerScreen.send)
        delegate?.tabViewControllerViewDidLoad(self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        delegate?.tabViewController(self, viewDidAppear: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        /// We hide the `Pulse` when the view is not visible
        // and on `viewDidAppear` we resume the introduction.
        PulseViewPresenter.shared.hide()
    }

    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        switch item {
        case sendTabBarItem:
            delegate?.sendClicked()
        case activityTabBarItem:
            delegate?.transactionsClicked()
        case receiveTabBarItem:
            delegate?.receiveClicked()
        case homeTabBarItem:
            delegate?.dashBoardClicked()
        case swapTabBarItem:
            delegate?.swapClicked()
        default:
            break
        }
    }

    func addTapGestureRecognizerToTabBar(_ tapGestureRecognizer: UITapGestureRecognizer) {
        guard tabBarGestureView == nil else { return }
        let tabBarGestureView = UIView(frame: tabBar.bounds)
        self.tabBarGestureView = tabBarGestureView
        tabBarGestureView.isUserInteractionEnabled = true
        tabBarGestureView.addGestureRecognizer(tapGestureRecognizer)
        tabBar.addSubview(tabBarGestureView)
    }

    func removeTapGestureRecognizerToTabBar(_ tapGestureRecognizer: UITapGestureRecognizer) {
        tabBarGestureView?.removeGestureRecognizer(tapGestureRecognizer)
        tabBarGestureView?.removeFromSuperview()
        tabBarGestureView = nil
    }

    @objc func setActiveViewController(_ newViewController: UIViewController, animated: Bool, index: Int) {
        guard newViewController != activeViewController else {
            return
        }
        activeViewController = newViewController
        selectedIndex = index
        insertActiveView()
        if let baseNavigationController = children.first as? BaseNavigationController {
            baseNavigationController.update()
        }
    }

    // MARK: - Private Methods

    private func insertActiveView() {
        if !contentView.subviews.isEmpty {
            contentView.subviews.first?.removeFromSuperview()
        }
        guard let activeViewController = activeViewController else {
            return
        }

        activeViewController.view.frame = contentView.bounds
        activeViewController.view.setNeedsLayout()
        contentView.addSubview(activeViewController.view)
    }
}
