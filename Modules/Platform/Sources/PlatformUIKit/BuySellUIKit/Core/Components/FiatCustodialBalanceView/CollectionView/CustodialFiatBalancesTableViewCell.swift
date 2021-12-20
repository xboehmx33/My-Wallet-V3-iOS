// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import RxCocoa
import RxSwift
import ToolKit
import UIKit

/// A cell that contains a horizontal collection view with the fiat balances
public final class FiatCustodialBalancesTableViewCell: UITableViewCell {

    // MARK: - Properties

    public var presenter: CurrencyViewPresenter! {
        willSet {
            disposeBag = DisposeBag()
        }
        didSet {
            guard presenter != nil else {
                return
            }
            guard let presenter = presenter as? FiatBalanceCollectionViewPresenter else {
                print("You should be passing a FiatBalanceCollectionViewPresenter here")
                abort()
            }
            collectionView.presenter = presenter
            presenter.presenters
                .map { $0.count > 1 }
                .drive(weak: self) { (self, hasMultipleBalances) in
                    if hasMultipleBalances {
                        self.collectionView.collectionViewFlowLayout.minimumLineSpacing = Spacing.inner
                        self.collectionView.collectionViewFlowLayout.minimumInteritemSpacing = Spacing.inner
                        self.collectionView.collectionViewFlowLayout.sectionInset = UIEdgeInsets(
                            top: 0,
                            left: Spacing.interItem,
                            bottom: 0,
                            right: Spacing.interItem
                        )
                        self.separatorView.isHidden = true
                    } else {
                        self.collectionView.collectionViewFlowLayout.minimumLineSpacing = 0
                        self.collectionView.collectionViewFlowLayout.minimumInteritemSpacing = 0
                        self.collectionView.collectionViewFlowLayout.sectionInset = .zero
                        self.separatorView.isHidden = false
                    }
                }
                .disposed(by: disposeBag)
            presenter.refresh()
        }
    }

    private var disposeBag = DisposeBag()
    private let collectionView: FiatBalanceCollectionView
    private let separatorView = UIView()

    // MARK: - Lifecycle

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        collectionView = FiatBalanceCollectionView()
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(collectionView)
        collectionView.fillSuperview()
        collectionView.layout(dimension: .height, to: 112, priority: .penultimateHigh)

        contentView.addSubview(separatorView)
        separatorView.backgroundColor = .lightBorder
        separatorView.layoutToSuperview(.leading, .trailing, .bottom)
        separatorView.layout(dimension: .height, to: 1)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { nil }

    override public func prepareForReuse() {
        presenter = nil
        super.prepareForReuse()
    }
}
