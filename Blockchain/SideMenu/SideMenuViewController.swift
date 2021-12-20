// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import AnalyticsKit
import Combine
import DIKit
import Foundation
import PlatformKit
import PlatformUIKit
import RxSwift
import ToolKit

protocol SideMenuViewControllerDelegate: AnyObject {
    func sideMenuViewController(_ viewController: SideMenuViewController, didTapOn item: SideMenuItem)
}

/// View controller displaying the side menu (hamburger menu) of the app
class SideMenuViewController: UIViewController {

    // MARK: - Types

    private enum SideMenuError: Error {
        case menuSwipeRecognizerViewNil
    }

    // MARK: - Public Properties

    weak var delegate: SideMenuViewControllerDelegate?

    /// This value should be the same as the `anchorRightPeekAmount` from the `ECSlidingViewController`
    /// It is then assigned to `SideMenuCell` for layout purposes
    var peekPadding: CGFloat = 0

    var createGestureRecognizers: (() -> (tapToCloseVC: UITapGestureRecognizer, tapToCloseTabBar: UITapGestureRecognizer)?)?

    weak var tabControllerManager: TabControllerManager?
    weak var slidingViewController: ECSlidingViewController?

    // MARK: - Private Properties

    @IBOutlet private var tableViewBackgroundView: UIView!
    @IBOutlet private var tableView: UITableView!
    @IBOutlet private var footerView: SideMenuFooterView!

    private var tapToCloseGestureRecognizerVC: UITapGestureRecognizer!
    private var tapToCloseGestureRecognizerTabBar: UITapGestureRecognizer!

    private let disposeBag = DisposeBag()

    private lazy var presenter: SideMenuPresenter = {
        SideMenuPresenter()
    }()

    private var sideMenuItems: [SideMenuItem] = [] {
        didSet {
            tableView.reloadData()
        }
    }

    private let recorder: ErrorRecording = CrashlyticsRecorder()
    private let analyticsRecorder: AnalyticsEventRecorderAPI = resolve()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - View Controller Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.NavigationBar.LightContent.background
        tableViewBackgroundView.backgroundColor = UIColor.NavigationBar.LightContent.background
        if let recognizers = createGestureRecognizers?() {
            tapToCloseGestureRecognizerTabBar = recognizers.tapToCloseTabBar
            tapToCloseGestureRecognizerVC = recognizers.tapToCloseVC
        } else {
            Logger.shared.warning("No gesture recognizers were set on \(self)")
        }
        registerCells()
        initializeTableView()
        addShadow()

        presenter
            .sideMenuItems
            .sink { [weak self] items in
                guard let self = self else { return }
                self.sideMenuItems = items
            }
            .store(in: &cancellables)

        presenter.sideMenuFooterItems
            .sink { [weak self] items in
                self?.footerView.model = .init(top: items.top, bottom: items.bottom)
            }
            .store(in: &cancellables)

        footerView.itemTapped
            .emit(weak: self) { (self, item) in
                self.didTapItem(item)
            }
            .disposed(by: disposeBag)

        presenter.itemSelection
            .emit(weak: self) { (self, item) in
                self.didTapItem(item)
            }
            .disposed(by: disposeBag)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setSideMenuGestures()
        addShadow()
    }

    override func viewWillDisappear(_ animated: Bool) {
        resetSideMenuGestures()
        super.viewWillDisappear(animated)
    }

    // MARK: - Public Methods

    func reload() {
        tableView?.reloadData()
    }

    // MARK: - Private Methods

    private func didTapItem(_ item: SideMenuItem) {
        analyticsRecorder.record(events: item.analyticsEvents)
        delegate?.sideMenuViewController(self, didTapOn: item)
    }

    private func registerCells() {
        tableView.registerNibCell(SideMenuCell.self, in: .main)
    }

    private func initializeTableView() {
        tableView.dataSource = self
        tableView.delegate = self
    }

    private func addShadow() {
        guard let view = slidingViewController?.topViewController.view else { return }
        view.layer.shadowOpacity = 0.3
        view.layer.shadowRadius = 10.0
        view.layer.shadowColor = UIColor.black.cgColor
    }

    private func setSideMenuGestures() {
        guard let tabControllerManager = tabControllerManager else { return }
        let tabViewController = tabControllerManager.tabViewController

        if let menuSwipeRecognizerView = tabViewController.menuSwipeRecognizerView {
            menuSwipeRecognizerView.isUserInteractionEnabled = false
        } else { // Record an error but continue - suspected crash
            recorder.error(SideMenuError.menuSwipeRecognizerViewNil)
        }

        // Enable Pan gesture and tap gesture to close sideMenu
        guard let slidingViewController = slidingViewController else {
            return
        }

        if let activeViewController = tabViewController.activeViewController {
            // Disable all interactions on main view
            activeViewController.view.subviews.forEach {
                $0.isUserInteractionEnabled = false
            }
            activeViewController.view.isUserInteractionEnabled = true
            activeViewController.view.addGestureRecognizer(slidingViewController.panGesture)
            activeViewController.view.addGestureRecognizer(tapToCloseGestureRecognizerVC)
        }

        tabViewController.addTapGestureRecognizerToTabBar(tapToCloseGestureRecognizerTabBar)
    }

    private func resetSideMenuGestures() {
        guard let tabControllerManager = tabControllerManager else { return }
        let tabViewController = tabControllerManager.tabViewController
        guard let slidingViewController = slidingViewController else { return }
        if let activeViewController = tabViewController.activeViewController {
            activeViewController.view.removeGestureRecognizer(slidingViewController.panGesture)
            activeViewController.view.removeGestureRecognizer(tapToCloseGestureRecognizerVC)
            activeViewController.view.subviews.forEach {
                $0.isUserInteractionEnabled = true
            }
        }

        tabViewController.removeTapGestureRecognizerToTabBar(tapToCloseGestureRecognizerTabBar)

        // Enable swipe to open side menu gesture on small bar on the left of main view
        tabViewController.menuSwipeRecognizerView.isUserInteractionEnabled = true
        tabViewController.menuSwipeRecognizerView.addGestureRecognizer(slidingViewController.panGesture)
    }
}

extension SideMenuViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sideMenuItems.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        SideMenuCell.defaultHeight
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let sideMenuCell = tableView
            .dequeueReusableCell(
                withIdentifier: SideMenuCell.identifier
            ) as? SideMenuCell
        else {
            Logger.shared.debug("Could not get SideMenuCell")
            return UITableViewCell()
        }
        sideMenuCell.peekPadding = peekPadding
        sideMenuCell.item = sideMenuItems[indexPath.row]
        return sideMenuCell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = sideMenuItems[indexPath.row]
        presenter.onItemSelection(item)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
