//
//  AppDelegate.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2017/08/06.
//  Copyright © 2017年 marty-suzuki. All rights reserved.
//

import UIKit
import GithubKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    let favoriteModel = FavoriteModel()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        if let viewControllers = (window?.rootViewController as? UITabBarController)?.viewControllers {
            for value in viewControllers.enumerated() {
                switch value {
                case let (0, nc as UINavigationController):
                    let searchVC = SearchViewController(
                        searchPresenter: SearchViewPresenter(
                            model: SearchModel(
                                sendRequest: ApiSession.shared.send,
                                asyncAfter: { DispatchQueue.global().asyncAfter(deadline: $0, execute: $1) }
                            ),
                            mainAsync: { work in DispatchQueue.main.async { work() } },
                            notificationCenter: .default
                        ),
                        makeRepositoryPresenter: { [favoriteModel] in
                            RepositoryViewPresenter(
                                repository: $0,
                                favoriteModel: favoriteModel
                            )
                        },
                        makeUserRepositoryPresenter: {
                            UserRepositoryViewPresenter(
                                model: RepositoryModel(
                                    user: $0,
                                    sendRequest: ApiSession.shared.send
                                ),
                                mainAsync: { work in DispatchQueue.main.async { work() } }
                            )
                        }
                    )
                    nc.setViewControllers([searchVC], animated: false)

                case let (1, nc as UINavigationController):
                    let favoriteVC = FavoriteViewController(
                        presenter: FavoriteViewPresenter(model: favoriteModel),
                        makeRepositoryPresenter: { [favoriteModel] in
                            RepositoryViewPresenter(
                                repository: $0,
                                favoriteModel: favoriteModel
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

