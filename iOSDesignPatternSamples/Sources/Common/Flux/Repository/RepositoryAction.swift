//
//  RepositoryAction.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2017/09/12.
//  Copyright © 2017年 marty-suzuki. All rights reserved.
//

import Combine
import GithubKit

final class RepositoryAction {

    private let dispatcher: RepositoryDispatcher
    private let model: RepositoryModelType
    private var cancellables = Set<AnyCancellable>()
    
    init(
        dispatcher: RepositoryDispatcher,
        model: RepositoryModelType
    ) {
        self.dispatcher = dispatcher
        self.model = model

//        model.response
//            .subscribe(onNext: {
//                dispatcher.lastPageInfo.accept($0.pageInfo)
//                dispatcher.addRepositories.accept($0.nodes)
//                dispatcher.repositoryTotalCount.accept($0.totalCount)
//            })
//            .disposed(by: disposeBag)

        model.isFetchingRepositoriesPublisher
            .sink {
                dispatcher.isRepositoryFetching.send($0)
            }
            .store(in: &cancellables)
    }
    
    func fetchRepositories(withUserID id: String, after: String?) {
        //model.fetchRepositories(withUserID: id, after: after)
    }

    func selectRepository(_ repository: Repository) {
        dispatcher.selectedRepository.send(repository)
    }

    func clearSelectedRepository() {
        dispatcher.selectedRepository.send(nil)
    }

    func addFavorite(_ repository: Repository) {
        dispatcher.addFavorite.send(repository)
    }

    func removeFavorite(_ repository: Repository) {
        dispatcher.removeFavorite.send(repository)
    }

    func pageInfo(_ pageInfo: PageInfo) {
        dispatcher.lastPageInfo.send(pageInfo)
    }

    func clearPageInfo() {
        dispatcher.lastPageInfo.send(nil)
    }

    func addRepositories(_ repositories: [Repository]) {
        dispatcher.addRepositories.send(repositories)
    }

    func removeAllRepositories() {
        dispatcher.removeAllRepositories.send()
    }

    func repositoryTotalCount(_ count: Int) {
        dispatcher.repositoryTotalCount.send(count)
    }

    func isRepositoriesFetching(_ isFetching: Bool) {
        dispatcher.isRepositoryFetching.send(isFetching)
    }
}
