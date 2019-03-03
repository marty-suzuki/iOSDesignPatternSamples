//
//  UserRepositoryViewModel.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2017/09/10.
//  Copyright © 2017年 marty-suzuki. All rights reserved.
//

import Foundation
import GithubKit
import RxSwift
import RxCocoa

final class UserRepositoryViewModel {
    let title: String

    var repositories: [Repository] {
        return model.repositoriesValue
    }

    var isFetchingRepositories: Bool {
        return model.isFetchingRepositoriesValue
    }

    let output: Output
    let input: Input

    private let model: RepositoryModel
    private let disposeBag = DisposeBag()

    init(user: User,
         favoritesOutput: Observable<[Repository]>,
         favoritesInput: AnyObserver<[Repository]>) {
        self.title = "\(user.login)'s Repositories"

        self.model = RepositoryModel(user: user)

        let _fetchRepositories = PublishRelay<Void>()
        let _selectedIndexPath = PublishRelay<IndexPath>()
        let _isReachedBottom = PublishRelay<Bool>()
        let _headerFooterView = PublishRelay<UIView>()

        self.input = Input(fetchRepositories: _fetchRepositories.asObserver(),
                           selectedIndexPath: _selectedIndexPath.asObserver(),
                           isReachedBottom: _isReachedBottom.asObserver(),
                           headerFooterView: _headerFooterView.asObserver(),
                           favorites: favoritesInput)

        do {
            let updateLoadingView = Observable.combineLatest(_headerFooterView,
                                                             model.isFetchingRepositories)

            let showRepository = _selectedIndexPath
                .withLatestFrom(model.repositories) { $1[$0.row] }

            let countString = Observable.combineLatest(model.totalCount, model.repositories)
                .map { "\($1.count) / \($0)" }
                .share(replay: 1, scope: .whileConnected)

            let reloadData = Observable.merge(model.repositories.map { _ in },
                                              model.totalCount.map { _ in },
                                              model.isFetchingRepositories.map { _ in })

            self.output = Output(updateLoadingView: updateLoadingView,
                                 showRepository: showRepository,
                                 countString: countString,
                                 reloadData: reloadData,
                                 favorites: favoritesOutput)
        }

        _isReachedBottom
            .distinctUntilChanged()
            .filter { $0 }
            .subscribe(onNext: { [model] _ in
                model.fetchRepositories()
            })
            .disposed(by: disposeBag)

        model.fetchRepositories()
    }
}

extension UserRepositoryViewModel {
    struct Output {
        let updateLoadingView: Observable<(UIView, Bool)>
        let showRepository: Observable<Repository>
        let countString: Observable<String>
        let reloadData: Observable<Void>
        let favorites: Observable<[Repository]>
    }

    struct Input {
        let fetchRepositories: AnyObserver<Void>
        let selectedIndexPath: AnyObserver<IndexPath>
        let isReachedBottom: AnyObserver<Bool>
        let headerFooterView: AnyObserver<UIView>
        let favorites: AnyObserver<[Repository]>
    }
}
