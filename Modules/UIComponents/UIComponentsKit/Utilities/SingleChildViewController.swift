// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import ToolKit
import UIKit

/// Helper for allowing types such as `Either` in `SingleChildViewController`
public protocol ViewControllerProvider {
    var viewController: UIViewController { get }
}

/// Autoconformance to use UIViewController directly in `SingleChildViewController`
extension UIViewController: ViewControllerProvider {
    public var viewController: UIViewController {
        self
    }
}

/// A container controller displaying a full size single child, forwarding appearance methods.
open class SingleChildViewController<Child: ViewControllerProvider>: UIViewController {

    // MARK: Public Properties

    /// The child `ViewControllerProvider` being displayed.
    /// This can be changed during runtime.
    public var child: Child {
        didSet {
            if isViewLoaded {
                updateChild(from: oldValue)
                updateChild(to: child)
            }
        }
    }

    // MARK: - Forwarding Properties

    override open var childForStatusBarStyle: UIViewController? { child.viewController }
    override open var childForStatusBarHidden: UIViewController? { child.viewController }
    override open var childForHomeIndicatorAutoHidden: UIViewController? { child.viewController }
    override open var childForScreenEdgesDeferringSystemGestures: UIViewController? { child.viewController }
    override open var childViewControllerForPointerLock: UIViewController? { child.viewController }
    override open var navigationItem: UINavigationItem { child.viewController.navigationItem }

    // MARK: Private Properties

    private var observers: [NSKeyValueObservation]?

    // MARK: Lifecycle

    /// Create a single child view controller
    /// - Parameter child: The initial child to be displayed
    public init(child: Child) {
        self.child = child
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override open func viewDidLoad() {
        super.viewDidLoad()

        updateChild(to: child)
    }

    // MARK: Open Functions

    /// Remove the old child & disconnect any observers.
    /// Called automatically in `child.didSet`
    ///
    /// Available here for overriding behaviour if anything additional needs to happen in oldValue teardown.
    /// Please ensure to call `super` when overriding.
    /// - Parameter oldValue: The old child `ViewControllerProvider` being removed.
    open func updateChild(from oldValue: Child) {
        observers = nil

        oldValue.viewController.willMove(toParent: nil)
        oldValue.viewController.view.removeFromSuperview()
        oldValue.viewController.removeFromParent()
    }

    /// Connect the new child's appearance methods and add to the view.
    /// Called automatically in `child.didSet` and `viewDidLoad`
    ///
    /// Available here for overriding behaviour if anything additional needs to happen in newValue setup.
    /// Please ensure to call `super` when overriding.
    /// - Parameter newValue: The new child `ViewControllerProvider` being added
    open func updateChild(to newValue: Child) {
        observers = [
            newValue.viewController.observe(
                \.title,
                options: [.initial, .new]
            ) { [weak self] child, _ in
                self?.title = child.title
            },

            newValue.viewController.observe(
                \.tabBarItem,
                options: [.initial, .new]
            ) { [weak self] child, _ in
                self?.tabBarItem = child.tabBarItem
            },

            newValue.viewController.observe(
                \.hidesBottomBarWhenPushed,
                options: [.initial, .new]
            ) { [weak self] child, _ in
                self?.hidesBottomBarWhenPushed = child.hidesBottomBarWhenPushed
            }
        ]

        addChild(newValue.viewController)
        newValue.viewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(newValue.viewController.view)
        newValue.viewController.view.constraint(edgesTo: view)
        newValue.viewController.didMove(toParent: self)
    }
}
