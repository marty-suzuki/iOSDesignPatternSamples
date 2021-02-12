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

    private let favoriteModel = FavoriteModel()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        if let viewControllers = (window?.rootViewController as? UITabBarController)?.viewControllers {
            for value in viewControllers.enumerated() {
                switch value {
                case let (0, nc as UINavigationController):
                    let searchVC = SearchViewController(
                        viewModel: SearchViewModel(
                            searchModel: SearchModel(
                                sendRequest: ApiSession.shared.send
                            )
                        ),
                        makeUserRepositoryViewModel: { [favoriteModel] in
                            UserRepositoryViewModel(
                                user: $0,
                                favoriteModel: favoriteModel,
                                repositoryModel: RepositoryModel(
                                    user: $0,
                                    sendRequest: ApiSession.shared.send
                                )
                            )
                        },
                        makeRepositoryViewModel: { [favoriteModel] in
                            RepositoryViewModel(
                                repository: $0,
                                favoritesModel: favoriteModel
                            )
                        }
                    )
                    nc.setViewControllers([searchVC], animated: false)

                case let (1, nc as UINavigationController):
                    let favoriteVC = FavoriteViewController(
                        viewModel: FavoriteViewModel(favoriteModel: favoriteModel),
                        makeRepositoryViewModel: { [favoriteModel] in
                            RepositoryViewModel(repository: $0, favoritesModel: favoriteModel)
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
