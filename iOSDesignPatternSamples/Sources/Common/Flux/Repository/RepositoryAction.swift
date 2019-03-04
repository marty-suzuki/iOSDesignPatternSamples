//
//  RepositoryAction.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2017/09/12.
//  Copyright © 2017年 marty-suzuki. All rights reserved.
//

import GithubKit
import RxSwift

final class RepositoryAction {

    private let dispatcher: RepositoryDispatcher
    private let model: RepositoryModel
    private let disposeBag = DisposeBag()
    
    init(dispatcher: RepositoryDispatcher,
         model: RepositoryModel) {
        self.dispatcher = dispatcher
        self.model = model

        model.response
            .subscribe(onNext: {
                dispatcher.lastPageInfo.accept($0.pageInfo)
                dispatcher.addRepositories.accept($0.nodes)
                dispatcher.repositoryTotalCount.accept($0.totalCount)
            })
            .disposed(by: disposeBag)

        model.isFetchingRepositories
            .subscribe(onNext: {
                dispatcher.isRepositoryFetching.accept($0)
            })
            .disposed(by: disposeBag)
    }
    
    func fetchRepositories(withUserID id: String, after: String?) {
        model.fetchRepositories(withUserID: id, after: after)
    }

    func selectRepository(_ repository: Repository) {
        dispatcher.selectedRepository.accept(repository)
    }

    func clearSelectedRepository() {
        dispatcher.selectedRepository.accept(nil)
    }

    func addFavorite(_ repository: Repository) {
        dispatcher.addFavorite.accept(repository)
    }

    func removeFavorite(_ repository: Repository) {
        dispatcher.removeFavorite.accept(repository)
    }

    func pageInfo(_ pageInfo: PageInfo) {
        dispatcher.lastPageInfo.accept(pageInfo)
    }

    func clearPageInfo() {
        dispatcher.lastPageInfo.accept(nil)
    }

    func addRepositories(_ repositories: [Repository]) {
        dispatcher.addRepositories.accept(repositories)
    }

    func removeAllRepositories() {
        dispatcher.removeAllRepositories.accept(())
    }

    func repositoryTotalCount(_ count: Int) {
        dispatcher.repositoryTotalCount.accept(count)
    }

    func isRepositoriesFetching(_ isFetching: Bool) {
        dispatcher.isRepositoryFetching.accept(isFetching)
    }
}
