//
//  RepositoryAction.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2017/09/12.
//  Copyright © 2017年 marty-suzuki. All rights reserved.
//

import Foundation
import FluxCapacitor
import GithubKit
import RxSwift

final class RepositoryAction: Actionable {
    typealias DispatchValueType = Dispatcher.Repository
    
    private let session: ApiSession
    private var disposeBag = DisposeBag()
    
    init(session: ApiSession = .shared) {
        self.session = session
    }
    
    func fetchRepositories(withUserId id: String, after: String?) {
        invoke(.isRepositoryFetching(true))
        let request = UserNodeRequest(id: id, after: after)
        session.rx.send(request)
            .subscribe(onNext: { [weak self] in
                self?.invoke(.lastPageInfo($0.pageInfo))
                self?.invoke(.addRepositories($0.nodes))
                self?.invoke(.repositoryTotalCount($0.totalCount))
            }, onDisposed: { [weak self] in
                self?.invoke(.isRepositoryFetching(false))
            })
            .disposed(by: disposeBag)
    }

    func selectRepository(_ repository: Repository) {
        invoke(.selectedRepository(repository))
    }

    func clearSelectedRepository() {
        invoke(.selectedRepository(nil))
    }

    func addFavorite(_ repository: Repository) {
        invoke(.addFavorite(repository))
    }

    func removeFavorite(_ repository: Repository) {
        invoke(.removeFavorite(repository))
    }

    func pageInfo(_ pageInfo: PageInfo) {
        invoke(.lastPageInfo(pageInfo))
    }

    func clearPageInfo() {
        invoke(.lastPageInfo(nil))
    }

    func addRepositories(_ repositories: [Repository]) {
        invoke(.addRepositories(repositories))
    }

    func removeAllRepositories() {
        invoke(.removeAllRepositories)
    }

    func repositoryTotalCount(_ count: Int) {
        invoke(.repositoryTotalCount(count))
    }

    func isRepositoriesFetching(_ isFetching: Bool) {
        invoke(.isRepositoryFetching(isFetching))
    }
}
