//
//  SearchViewController.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2017/08/06.
//  Copyright © 2017年 marty-suzuki. All rights reserved.
//

import UIKit
import GithubKit
import RxSwift
import RxCocoa

final class SearchViewController: UIViewController {
    @IBOutlet weak var totalCountLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewBottomConstraint: NSLayoutConstraint!

    var favoritesInput: AnyObserver<[Repository]>?
    var favoritesOutput: Observable<[Repository]>?

    private let searchBar = UISearchBar(frame: .zero)
    private let loadingView = LoadingView.makeFromNib()

    private let _selectedIndexPath = PublishSubject<IndexPath>()
    private let _isReachedBottom = PublishSubject<Bool>()
    private let _headerFooterView = PublishSubject<UIView>()

    private lazy var dataSource: SearchViewDataSource = {
        .init(viewModel: self.viewModel,
              selectedIndexPath: self._selectedIndexPath.asObserver(),
              isReachedBottom: self._isReachedBottom.asObserver(),
              headerFooterView: self._headerFooterView.asObserver())
    }()
    private lazy var viewModel: SearchViewModel = {
        let viewDidAppear = self.rx
            .methodInvoked(#selector(SearchViewController.viewDidAppear(_:)))
            .map { _ in }
        let viewDidDisappear = self.rx
            .methodInvoked(#selector(SearchViewController.viewDidDisappear(_:)))
            .map { _ in }
        return .init(viewDidAppear: viewDidAppear,
                     viewDidDisappear: viewDidDisappear,
                     searchText: self.searchBar.rx.text.orEmpty,
                     isReachedBottom: self._isReachedBottom,
                     selectedIndexPath: self._selectedIndexPath,
                     headerFooterView: self._headerFooterView)
    }()

    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.titleView = searchBar
        searchBar.placeholder = "Input user name"
        dataSource.configure(with: tableView)

        // observe viewModel
        viewModel.accessTokenAlert
            .bind(to: showAccessTokenAlert)
            .disposed(by: disposeBag)

        viewModel.keyboardWillShow
            .bind(to: keyboardWillShow)
            .disposed(by: disposeBag)

        viewModel.keyboardWillHide
            .bind(to: keyboardWillHide)
            .disposed(by: disposeBag)

        viewModel.countString
            .bind(to: totalCountLabel.rx.text)
            .disposed(by: disposeBag)

        viewModel.reloadData
            .bind(to: reloadData)
            .disposed(by: disposeBag)

        viewModel.selectedUser
            .bind(to: showUserRepository)
            .disposed(by: disposeBag)

        viewModel.updateLoadingView
            .bind(to: updateLoadingView)
            .disposed(by: disposeBag)

        // observe views
        Observable.merge(searchBar.rx.searchButtonClicked.asObservable(),
                         searchBar.rx.cancelButtonClicked.asObservable())
            .subscribe(onNext: { [weak self] in
                self?.searchBar.resignFirstResponder()
                self?.searchBar.showsCancelButton = false
            })
            .disposed(by: disposeBag)

        searchBar.rx.textDidBeginEditing
            .subscribe(onNext: { [weak self] in
                self?.searchBar.showsCancelButton = true
            })
            .disposed(by: disposeBag)
        
        rx.methodInvoked(#selector(SearchViewController.viewWillDisappear(_:)))
            .map { _ in }
            .subscribe(onNext: { [weak self] in
                self?.searchBar.resignFirstResponder()
            })
            .disposed(by: disposeBag)
    }

    private var showAccessTokenAlert: AnyObserver<(String, String)> {
        return Binder(self) { (me, value: (title: String, message: String)) in
            let alert = UIAlertController(title: value.title, message: value.message, preferredStyle: .alert)
            me.present(alert, animated: false, completion: nil)
        }.asObserver()
    }

    private var reloadData: AnyObserver<Void>  {
        return Binder(self) { me, _ in
            me.tableView.reloadData()
        }.asObserver()
    }
    
    private var keyboardWillShow: AnyObserver<UIKeyboardInfo> {
        return Binder(self) { me, keyboardInfo in
            me.view.layoutIfNeeded()
            let extra = me.tabBarController?.tabBar.bounds.height ?? 0
            me.tableViewBottomConstraint.constant = keyboardInfo.frame.size.height - extra
            UIView.animate(withDuration: keyboardInfo.animationDuration,
                           delay: 0,
                           options: keyboardInfo.animationCurve,
                           animations: { me.view.layoutIfNeeded() },
                           completion: nil)
        }.asObserver()
    }
    
    private var  keyboardWillHide: AnyObserver<UIKeyboardInfo> {
        return Binder(self) { me, keyboardInfo in
            me.view.layoutIfNeeded()
            me.tableViewBottomConstraint.constant = 0
            UIView.animate(withDuration: keyboardInfo.animationDuration,
                           delay: 0,
                           options: keyboardInfo.animationCurve,
                           animations: { me.view.layoutIfNeeded() },
                           completion: nil)
        }.asObserver()
    }
    
    private var showUserRepository: AnyObserver<User> {
        return Binder(self) { me, user in
            guard let favoritesOutput = me.favoritesOutput, let favoritesInput = me.favoritesInput else { return }
            let vc = UserRepositoryViewController(user: user,
                                                  favoritesOutput: favoritesOutput,
                                                  favoritesInput: favoritesInput)
            me.navigationController?.pushViewController(vc, animated: true)
        }.asObserver()
    }
    
    private var updateLoadingView: AnyObserver<(UIView, Bool)> {
        return Binder(self) { (me, value: (view: UIView, isLoading: Bool)) in
            me.loadingView.removeFromSuperview()
            me.loadingView.isLoading = value.isLoading
            me.loadingView.add(to: value.view)
        }.asObserver()
    }
}
