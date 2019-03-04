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

    let flux = Flux(searchModel: .init(), repositoryModel: .init())

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        if let viewControllers = (window?.rootViewController as? UITabBarController)?.viewControllers {
            for value in viewControllers.enumerated() {
                switch value {
                case let (0, nc as UINavigationController):
                    let searchVC = SearchViewController(flux: flux)
                    nc.setViewControllers([searchVC], animated: false)

                case let (1, nc as UINavigationController):
                    let searchVC = FavoriteViewController(flux: flux)
                    nc.setViewControllers([searchVC], animated: false)

                default:
                    continue
                }
            }
        }

        return true
    }
}

