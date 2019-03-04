//
//  AppDelegate.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2017/08/06.
//  Copyright © 2017年 marty-suzuki. All rights reserved.
//

import UIKit
import GithubKit
import RxCocoa
import RxSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    let favoritesRelay = BehaviorRelay<[Repository]>(value: [])

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        let favoritesOutput = favoritesRelay.asObservable()
        let favoritesInput = favoritesRelay.asObserver()

        if let viewControllers = (window?.rootViewController as? UITabBarController)?.viewControllers {
            for value in viewControllers.enumerated() {
                switch value {
                case let (0, nc as UINavigationController):
                    let searchVC = SearchViewController(favoritesInput: favoritesInput, favoritesOutput: favoritesOutput)
                    nc.setViewControllers([searchVC], animated: false)

                case let (1, nc as UINavigationController):
                    let favoriteVC = FavoriteViewController(favoritesInput: favoritesInput, favoritesOutput: favoritesOutput)
                    nc.setViewControllers([favoriteVC], animated: false)

                default:
                    continue
                }
            }
        }

        return true
    }
}

