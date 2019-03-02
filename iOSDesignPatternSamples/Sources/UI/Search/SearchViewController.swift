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

    private let dataSource: SearchViewDataSource
    private let viewModel: SearchViewModel

    private let disposeBag = DisposeBag()

    init(favoritesInput: AnyObserver<[Repository]>,
         favoritesOutput: Observable<[Repository]>) {
        self.viewModel = SearchViewModel(favoritesOutput: favoritesOutput, favoritesInput: favoritesInput)
        self.dataSource = SearchViewDataSource(viewModel: viewModel)
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

        rx.methodInvoked(#selector(SearchViewController.viewDidAppear(_:)))
            .map { _ in }
            .bind(to: viewModel.input.viewDidAppear)
            .disposed(by: disposeBag)

        rx.methodInvoked(#selector(SearchViewController.viewDidDisappear(_:)))
            .map { _ in }
            .bind(to: viewModel.input.viewDidDisappear)
            .disposed(by: disposeBag)

        searchBar.rx.text.orEmpty
            .bind(to: viewModel.input.searchText)
            .disposed(by: disposeBag)

        // observe viewModel
        viewModel.output.accessTokenAlert
            .bind(to: showAccessTokenAlert)
            .disposed(by: disposeBag)

        viewModel.output.keyboardWillShow
            .bind(to: keyboardWillShow)
            .disposed(by: disposeBag)

        viewModel.output.keyboardWillHide
            .bind(to: keyboardWillHide)
            .disposed(by: disposeBag)

        viewModel.output.countString
            .bind(to: totalCountLabel.rx.text)
            .disposed(by: disposeBag)

        viewModel.output.reloadData
            .bind(to: reloadData)
            .disposed(by: disposeBag)

        viewModel.output.selectedUser
            .bind(to: showUserRepository)
            .disposed(by: disposeBag)

        viewModel.output.updateLoadingView
            .bind(to: updateLoadingView)
            .disposed(by: disposeBag)

        // observe views
        Observable.merge(searchBar.rx.searchButtonClicked.asObservable(),
                         searchBar.rx.cancelButtonClicked.asObservable())
            .bind(to: Binder(searchBar) { searchBar, _ in
                searchBar.resignFirstResponder()
                searchBar.showsCancelButton = false
            })
            .disposed(by: disposeBag)

        searchBar.rx.textDidBeginEditing
            .bind(to: Binder(searchBar) { searchBar, _ in
                searchBar.showsCancelButton = true
            })
            .disposed(by: disposeBag)
        
        rx.methodInvoked(#selector(SearchViewController.viewWillDisappear(_:)))
            .bind(to: Binder(searchBar) { searchBar, _ in
                searchBar.resignFirstResponder()
            })
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
    
    private var showUserRepository: Binder<User> {
        return Binder(self) { me, user in
            let vc = UserRepositoryViewController(user: user,
                                                  favoritesOutput: me.viewModel.output.favorites,
                                                  favoritesInput: me.viewModel.input.favorites)
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
