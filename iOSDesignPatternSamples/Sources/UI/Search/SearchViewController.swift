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
    
    private let dataSource = SearchViewDataSource()
    private let action = UserAction()
    private let store: UserStore = .instantiate()
    private let disposeBag = DisposeBag()
    private var pool = NoticeObserverPool()

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.titleView = searchBar
        searchBar.placeholder = "Input user name"
        dataSource.configure(with: tableView)

        // observe store
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
                self?.pool = NoticeObserverPool()
            })
            .disposed(by: disposeBag)

         // keyboard notification
        viewDidAppear
            .flatMap { [weak self] _ -> Observable<UIKeyboardInfo> in
                Observable.create { observer in
                    let disposable = Disposables.create()
                    guard let me = self else { return disposable }
                    UIKeyboardWillShow.observe {
                        observer.onNext($0)
                    }
                    .disposed(by: me.pool)
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
                    UIKeyboardWillHide.observe {
                        observer.onNext($0)
                    }
                    .disposed(by: me.pool)
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
            .subscribe(onNext: { [weak self] _ in
                self?.action.clearPageInfo()
                self?.action.removeAllUsers()
                self?.action.userTotalCount(0)
            })
            .disposed(by: disposeBag)

        Observable.merge(initialLoad, loadMore)
            .map { SearchUserRequest(query: $0, after: $1) }
            .distinctUntilChanged { $0.query == $1.query && $0.after == $1.after }
            .subscribe(onNext: { [weak self] request in
                self?.action.fetchUsers(withQuery: request.query, after: request.after)
            })
            .disposed(by: disposeBag)

        Observable.merge(viewDidAppear.map { _ in true },
                         viewDidDisappear.map { _ in false })
            .flatMapLatest { [weak self] isAppearing in
                self.map { $0.store.fetchError } ?? .empty()
            }
            .flatMap { error -> Observable<(String, String)> in
                guard case .emptyToken? = (error as? ApiSession.Error) else { return .empty() }
                let title = "Access Token Error"
                let message = "\"Github Personal Access Token\" is Required.\n Please set it in ApiSession.extension.swift!"
                return .just((title, message))
            }
            .bind(to: showAccessTokenAlert)
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
    
    private var showUserRepository: AnyObserver<Void> {
        return Binder(self) { me, _ in
            let vc = UserRepositoryViewController()
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
