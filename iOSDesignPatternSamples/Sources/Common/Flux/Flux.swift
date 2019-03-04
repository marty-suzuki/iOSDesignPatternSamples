//
//  Flux.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2019/03/05.
//  Copyright © 2019 marty-suzuki. All rights reserved.
//

final class Flux {

    let userAction: UserAction
    let userStore: UserStore
    let repositoryAction: RepositoryAction
    let repositoryStore: RepositoryStore

    init(searchModel: SearchModel,
         repositoryModel: RepositoryModel) {
        let userDispatcher = UserDispatcher()
        self.userAction = UserAction(dispatcher: userDispatcher, model: searchModel)
        self.userStore = UserStore(dispatcher: userDispatcher)

        let repositoryDispatcher = RepositoryDispatcher()
        self.repositoryAction = RepositoryAction(dispatcher: repositoryDispatcher, model: repositoryModel)
        self.repositoryStore = RepositoryStore(dispatcher: repositoryDispatcher)
    }
}
