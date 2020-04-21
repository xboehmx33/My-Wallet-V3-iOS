//
//  SelectionScreenPresenter.swift
//  PlatformUIKit
//
//  Created by Daniel Huri on 30/01/2020.
//  Copyright © 2020 Blockchain Luxembourg S.A. All rights reserved.
//

import RxSwift
import RxRelay
import RxCocoa
import ToolKit
import PlatformKit

public final class SelectionScreenPresenter {
    
    // MARK: - Properties
    
    let title: String
    let tableHeaderViewModel: SelectionScreenTableHeaderViewModel?
    let searchBarPlaceholder: String
    var presenters: Observable<[SelectionItemViewPresenter]> {
        presentersRelay.asObservable()
    }
    
    var shouldPreselect: Observable<Bool> {
        preselectionSupportedRelay.asObservable()
    }
    
    var displayPresenters: Observable<[SelectionItemViewPresenter]> {
        displayPresentersRelay.asObservable()
    }
    
    var preselection: Observable<Int> {
        Observable.combineLatest(selectionRelay, preselectionSupportedRelay)
            .filter { $0.1 }
            .compactMap { $0.0 }
            .observeOn(MainScheduler.instance)
    }
    
    var selection: Observable<Int> {
        Observable.combineLatest(selectionRelay, preselectionSupportedRelay)
            .filter { !$0.1 }
            .compactMap { $0.0 }
            .observeOn(MainScheduler.instance)
    }
    
    let searchTextRelay = BehaviorRelay<String>(value: "")
    var searchText: Observable<String> {
        searchTextRelay.map { $0.lowercased() } 
    }
    
    let preSelectionRelay = PublishRelay<Int>()
    private let preselectionSupportedRelay = BehaviorRelay<Bool>(value: true)
    private let selectionRelay = BehaviorRelay<Int?>(value: nil)
    private let displayPresentersRelay = BehaviorRelay<[SelectionItemViewPresenter]>(value: [])
    private let presentersRelay = BehaviorRelay<[SelectionItemViewPresenter]>(value: [])
    private let interactor: SelectionScreenInteractor
    private let disposeBag = DisposeBag()
    
    // MARK: - Setup
    
    public init(title: String,
                description: String? = nil,
                shouldPreselect: Bool = true,
                searchBarPlaceholder: String,
                interactor: SelectionScreenInteractor) {
        self.preselectionSupportedRelay.accept(shouldPreselect)
        self.tableHeaderViewModel = SelectionScreenTableHeaderViewModel(title: description)
        self.searchBarPlaceholder = searchBarPlaceholder
        self.title = title
        self.interactor = interactor
        
        setupPresenters()
        setupSearch()
        
        guard shouldPreselect else { return }
        setupDefaultSelection()
    }
    
    private func setupPresenters() {
        interactor.interactors
            .map { interactors in
                interactors.map { SelectionItemViewPresenter(interactor: $0) }
            }
            .bind(to: presentersRelay)
            .disposed(by: disposeBag)
        
        presentersRelay
            .filter { !$0.isEmpty }
            .take(1)
            .bind(weak: self) { (self, presenters) in
                presenters
                    .enumerated()
                    .forEach { (index, presenter) in
                        presenter.setup {
                            guard self.selectionRelay.value != index else { return }
                            if let previousIndex = self.selectionRelay.value {
                                presenters[previousIndex].deselect()
                            }
                            
                            presenters[index].select()
                            self.selectionRelay.accept(index)
                        }
                    }
            }
            .disposed(by: disposeBag)
    }
    
    private func setupSearch() {
        searchText
            .flatMapLatest(weak: self) { (self, text) in
                self.presenters
                    .map { presenters in
                        guard !text.isEmpty else {
                            return presenters
                        }
                        return presenters.filter { $0.contains(text: text) }
                    }
            }
            .bind(to: displayPresentersRelay)
            .disposed(by: disposeBag)
    }
    
    private func setupDefaultSelection() {
        
        let presenters = self.presenters
            .filter { !$0.isEmpty }
        
        let selectedIndex = Observable
            .zip(
                presenters.take(1),
                interactor.service.selectedDataRelay.take(1)
            )
            .compactMap { (presenters, selectedData) in
                presenters.firstIndex { $0.data == selectedData }
            }
            .share(replay: 1)
        
        Observable
            .zip(
                presenters,
                selectedIndex
            )
            .take(1)
            .bind { (presenters, selectedIndex) in
                presenters[selectedIndex].select()
            }
            .disposed(by: disposeBag)
        
        selectedIndex
            .bind(to: selectionRelay)
            .disposed(by: disposeBag)
    }

    func navigationBarLeadingButtonTapped() {
        /// if `True` -> interator fires!
        if preselectionSupportedRelay.value {
            interactor.recordSelection()
        } else {
            interactor.dissmisRelay.accept(())
        }
    }
    
    func recordSelection() {
        interactor.recordSelection()
    }
}