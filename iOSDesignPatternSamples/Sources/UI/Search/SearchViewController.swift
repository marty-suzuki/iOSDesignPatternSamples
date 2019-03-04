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
import NoticeObserveKit

final class SearchViewController: UIViewController {
    @IBOutlet weak var totalCountLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewBottomConstraint: NSLayoutConstraint!

    private let searchBar = UISearchBar(frame: .zero)
    private let loadingView = LoadingView.makeFromNib()
    
    private let dataSource: SearchViewDataSource
    private let flux: Flux
    private let disposeBag = DisposeBag()
    private var pool = Notice.ObserverPool()

    init(flux: Flux) {
        self.flux = flux
        self.dataSource = SearchViewDataSource(flux: flux)
        super.init(nibName: SearchViewController.className, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.titleView = searchBar
        searchBar.placeholder = "Input user name"
        dataSource.configure(with: tableView)

        // observe store
        let store = flux.userStore
        let action = flux.userAction
        let users = store.users.asObservable()
        let totalCount = store.userTotalCount.asObservable()
        let isFetching = store.isUserFetching.asObservable()

        store.selectedUser
            .filter { $0 != nil }
            .map { _ in }
            .bind(to: showUserRepository)
            .disposed(by: disposeBag)

        Observable.merge(users.map { _ in },
                         totalCount.map { _ in },
                         isFetching.map { _ in })
            .bind(to: reloadData)
            .disposed(by: disposeBag)

        Observable.combineLatest(dataSource.headerFooterView, isFetching)
            .bind(to: updateLoadingView)
            .disposed(by: disposeBag)

        Observable.zip(totalCount, users)
            .map { "\($1.count) / \($0)" }
            .bind(to: totalCountLabel.rx.text)
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

        let viewDidAppear = rx.methodInvoked(#selector(SearchViewController.viewDidAppear(_:)))
        let viewDidDisappear = rx.methodInvoked(#selector(SearchViewController.viewDidDisappear(_:)))

        viewDidDisappear
            .subscribe(onNext: { [weak self] _ in
                self?.searchBar.resignFirstResponder()
                self?.pool = Notice.ObserverPool()
            })
            .disposed(by: disposeBag)

         // keyboard notification
        viewDidAppear
            .flatMap { [weak self] _ -> Observable<UIKeyboardInfo> in
                Observable.create { observer in
                    let disposable = Disposables.create()
                    guard let me = self else { return disposable }
                    NotificationCenter.default.nok.observe(name: .keyboardWillShow) {
                        observer.onNext($0)
                    }
                    .invalidated(by: me.pool)
                    return disposable
                }
            }
            .bind(to: keyboardWillShow)
            .disposed(by: disposeBag)

        viewDidAppear
            .flatMap { [weak self] _ -> Observable<UIKeyboardInfo> in
                Observable.create { observer in
                    let disposable = Disposables.create()
                    guard let me = self else { return disposable }
                    NotificationCenter.default.nok.observe(name: .keyboardWillHide) {
                        observer.onNext($0)
                    }
                    .invalidated(by: me.pool)
                    return disposable
                }
            }
            .bind(to: keyboardWillHide)
            .disposed(by: disposeBag)

        // search
        let query = searchBar.rx.text.orEmpty
            .debounce(0.3, scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .share()

        let endCousor = store.lastPageInfo.asObservable()
            .map { $0?.endCursor }
            .share()

        let initialLoad = query
            .filter { !$0.isEmpty }
            .withLatestFrom(endCousor) { ($0, $1) }

        let loadMore = dataSource.isReachedBottom
            .filter { $0 }
            .withLatestFrom(Observable.combineLatest(query, endCousor)) { $1 }
            .filter { !$0.isEmpty && $1 != nil }

        query
            .subscribe(onNext: { _ in
                action.clearPageInfo()
                action.removeAllUsers()
                action.userTotalCount(0)
            })
            .disposed(by: disposeBag)

        Observable.merge(initialLoad, loadMore)
            .map { SearchUserRequest(query: $0, after: $1) }
            .distinctUntilChanged { $0.query == $1.query && $0.after == $1.after }
            .subscribe(onNext: { request in
                action.fetchUsers(withQuery: request.query, after: request.after)
            })
            .disposed(by: disposeBag)

        Observable.merge(viewDidAppear.map { _ in true },
                         viewDidDisappear.map { _ in false })
            .flatMapLatest { isAppearing in
                isAppearing ? store.fetchError : .empty()
            }
            .bind(to: showAccessTokenAlert)
            .disposed(by: disposeBag)
    }

    private var showAccessTokenAlert: Binder<ErrorMessage> {
        return Binder(self) { me, error in
            let alert = UIAlertController(title: error.title, message: error.message, preferredStyle: .alert)
            me.present(alert, animated: false, completion: nil)
        }
    }

    private var reloadData: Binder<Void>  {
        return Binder(self) { me, _ in
            me.tableView.reloadData()
        }
    }
    
    private var keyboardWillShow: Binder<UIKeyboardInfo> {
        return Binder(self) { me, keyboardInfo in
            me.view.layoutIfNeeded()
            let extra = me.tabBarController?.tabBar.bounds.height ?? 0
            me.tableViewBottomConstraint.constant = keyboardInfo.frame.size.height - extra
            UIView.animate(withDuration: keyboardInfo.animationDuration,
                           delay: 0,
                           options: keyboardInfo.animationCurve,
                           animations: { me.view.layoutIfNeeded() },
                           completion: nil)
        }
    }
    
    private var keyboardWillHide: Binder<UIKeyboardInfo> {
        return Binder(self) { me, keyboardInfo in
            me.view.layoutIfNeeded()
            me.tableViewBottomConstraint.constant = 0
            UIView.animate(withDuration: keyboardInfo.animationDuration,
                           delay: 0,
                           options: keyboardInfo.animationCurve,
                           animations: { me.view.layoutIfNeeded() },
                           completion: nil)
        }
    }
    
    private var showUserRepository: Binder<Void> {
        return Binder(self) { me, _ in
            let vc = UserRepositoryViewController(flux: me.flux)
            me.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    private var updateLoadingView: Binder<(UIView, Bool)> {
        return Binder(self) { (me, value: (view: UIView, isLoading: Bool)) in
            me.loadingView.removeFromSuperview()
            me.loadingView.isLoading = value.isLoading
            me.loadingView.add(to: value.view)
        }
    }
}
