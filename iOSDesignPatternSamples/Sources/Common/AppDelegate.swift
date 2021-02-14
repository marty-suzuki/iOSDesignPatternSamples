//
//  AppDelegate.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2017/08/06.
//  Copyright © 2017年 marty-suzuki. All rights reserved.
//

import Combine
import GithubKit
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    let favoriteModel = FavoriteModel()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        if let viewControllers = (window?.rootViewController as? UITabBarController)?.viewControllers {
            for value in viewControllers.enumerated() {
                switch value {
                case let (0, nc as UINavigationController):
                    let repositoryDispatcher = RepositoryDispatcher()
                    let searchDispatcher = SearchDispatcher()
                    let userRepositoryDispatcher = UserRepositoryDispatcher()
                    let searchVC = SearchViewController(
                        action: SearchAction(
                            notificationCenter: .default,
                            dispatcher: searchDispatcher,
                            searchModel: SearchModel(
                                sendRequest: ApiSession.shared.send
                            ),
                            notificationCenter: .default
                        ),
                        store: SearchStore(
                            dispatcher: searchDispatcher
                        ),
                        makeUserRepositoryAction: { user in
                            UserRepositoryAction(
                                dispatcher: userRepositoryDispatcher,
                                repositoryModel: RepositoryModel(
                                    user: user,
                                    sendRequest: ApiSession.shared.send
                                )
                            )
                        },
                        makeUserRepositoryStore: { user in
                            UserRepositoryStore(
                                user: user,
                                dispatcher: userRepositoryDispatcher
                            )
                        },
                        makeRepositoryAction: { [favoriteModel] repository in
                            RepositoryAction(
                                repository: repository,
                                dispatcher: repositoryDispatcher,
                                favoriteModel: favoriteModel
                            )
                        },
                        makeRepositoryStore: { repository in
                            RepositoryStore(
                                repository: repository,
                                dispatcher: repositoryDispatcher
                            )
                        }
                    )
                    nc.setViewControllers([searchVC], animated: false)

                case let (1, nc as UINavigationController):
                    let favoriteDispatcher = FavoriteDispatcher()
                    let repositoryDispatcher = RepositoryDispatcher()
                    let favoriteVC = FavoriteViewController(
                        action: FavoriteAction(
                            dispatcher: favoriteDispatcher,
                            favoriteModel: favoriteModel
                        ),
                        store: FavoriteStore(
                            dispatcher: favoriteDispatcher
                        ),
                        makeRepositoryAction: { [favoriteModel] repository in
                            RepositoryAction(
                                repository: repository,
                                dispatcher: repositoryDispatcher,
                                favoriteModel: favoriteModel
                            )
                        },
                        makeRepositoryStore: { repository in
                            RepositoryStore(
                                repository: repository,
                                dispatcher: repositoryDispatcher
                            )
                        }
                    )
                    nc.setViewControllers([favoriteVC], animated: false)

                default:
                    continue
                }
            }
        }

        return true
    }
}
