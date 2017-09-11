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

    private let searchBar = UISearchBar(frame: .zero)
    private let loadingView = LoadingView.makeFromNib()
    
    var favoritesInput: AnyObserver<[Repository]>?
    var favoritesOutput: Observable<[Repository]>?

    private lazy var dataSource: SearchViewDataSource = .init(viewModel: self.viewModel)
    private lazy var viewModel: SearchViewModel = {
        let viewWillAppear = self.rx
            .methodInvoked(#selector(SearchViewController.viewWillAppear(_:)))
            .map { _ in }
        let viewWillDisappear = self.rx
            .methodInvoked(#selector(SearchViewController.viewWillDisappear(_:)))
            .map { _ in }
        let viewDidAppear = self.rx
            .methodInvoked(#selector(SearchViewController.viewDidAppear(_:)))
            .map { _ in }
        return .init(viewWillAppear: viewWillAppear,
                     viewWillDisappear: viewWillDisappear,
                     viewDidAppear: viewDidAppear,
                     searchText: self.searchBar.rx.text.orEmpty,
                     isReachedBottom: self.isReachedBottom,
                     selectedIndexPath: self.selectedIndexPath,
                     headerFooterView: self.headerFooterView)
    }()

    private let selectedIndexPath = PublishSubject<IndexPath>()
    private let isReachedBottom = PublishSubject<Bool>()
    private let headerFooterView = PublishSubject<UIView>()
    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.titleView = searchBar
        searchBar.placeholder = "Input user name"

        dataSource.configure(with: tableView)

        dataSource.selectedIndexPath
            .bind(to: selectedIndexPath)
            .disposed(by: disposeBag)

        dataSource.isReachedBottom
            .bind(to: isReachedBottom)
            .disposed(by: disposeBag)

        dataSource.headerFooterView
            .bind(to: headerFooterView)
            .disposed(by: disposeBag)

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
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if searchBar.isFirstResponder {
            searchBar.resignFirstResponder()
        }
    }

    private var showAccessTokenAlert: AnyObserver<(String, String)> {
        return UIBindingObserver(UIElement: self) { (me, value: (title: String, message: String)) in
            let alert = UIAlertController(title: value.title, message: value.message, preferredStyle: .alert)
            me.present(alert, animated: false, completion: nil)
        }.asObserver()
    }

    private var reloadData: AnyObserver<Void>  {
        return UIBindingObserver(UIElement: self) { me, _ in
            me.tableView.reloadData()
        }.asObserver()
    }
    
    private var keyboardWillShow: AnyObserver<UIKeyboardInfo> {
        return UIBindingObserver(UIElement: self) { me, keyboardInfo in
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
        return UIBindingObserver(UIElement: self) { me, keyboardInfo in
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
        return UIBindingObserver(UIElement: self) { me, user in
            guard let favoritesOutput = me.favoritesOutput, let favoritesInput = me.favoritesInput else { return }
            let vc = UserRepositoryViewController(user: user,
                                                  favoritesOutput: favoritesOutput,
                                                  favoritesInput: favoritesInput)
            me.navigationController?.pushViewController(vc, animated: true)
        }.asObserver()
    }
    
    private var updateLoadingView: AnyObserver<(UIView, Bool)> {
        return UIBindingObserver(UIElement: self) { (me, value: (view: UIView, isLoading: Bool)) in
            me.loadingView.removeFromSuperview()
            me.loadingView.isLoading = value.isLoading
            me.loadingView.add(to: value.view)
        }.asObserver()
    }
}
