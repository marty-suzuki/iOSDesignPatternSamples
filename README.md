# iOSDesignPatternSamples (MVP)

This is Github user search demo app that made with MVP design pattern.

## Application Structure

![](./Images/structure.png)

## ViewControllers

### [SearchViewController](./iOSDesignPatternSamples/Sources/UI/Search/SearchViewController.swift)
Search Github user and show user result list

- [SearchView](./iOSDesignPatternSamples/Sources/UI/Search/SearchViewController.swift)
- [SearchPresenter](./iOSDesignPatternSamples/Sources/UI/Search/SearchViewPresenter.swift)
- [SearchViewPresenter](./iOSDesignPatternSamples/Sources/UI/Search/SearchViewPresenter.swift)

### [FavoriteViewController](./iOSDesignPatternSamples/Sources/UI/Favorite/FavoriteViewController.swift)
Show local on memory favorite repositories

- [FavoriteView](./iOSDesignPatternSamples/Sources/UI/Favorite/FavoriteViewController.swift)
- [FavoritePresenter](./iOSDesignPatternSamples/Sources/UI/Favorite/FavoriteViewPresenter.swift)
- [FavoriteViewPresenter](./iOSDesignPatternSamples/Sources/UI/Favorite/FavoriteViewPresenter.swift)

### [UserRepositoryViewController](./iOSDesignPatternSamples/Sources/UI/UserRepository/UserRepositoryViewController.swift)
Show Github user's repositories

- [UserRepositoryView](./iOSDesignPatternSamples/Sources/UI/UserRepository/UserRepositoryViewController.swift)
- [UserRepositoryPresenter](./iOSDesignPatternSamples/Sources/UI/UserRepository/UserRepositoryViewPresenter.swift)
- [UserRepositoryViewPresenter](./iOSDesignPatternSamples/Sources/UI/UserRepository/UserRepositoryViewPresenter.swift)

### [RepositoryViewController](./iOSDesignPatternSamples/Sources/UI/Repository/RepositoryViewController.swift)
Show a repository and add / remove local on memory favorites

- [RepositoryView](./iOSDesignPatternSamples/Sources/UI/Repository/RepositoryViewController.swift)
- [RepositoryPresenter](./iOSDesignPatternSamples/Sources/UI/Repository/RepositoryViewPresenter.swift)
- [RepositoryViewPresenter](./iOSDesignPatternSamples/Sources/UI/Repository/RepositoryViewPresenter.swift)

## How to add / remove favorites

You can add / remove favorite repositories in RepositoryViewController, but an Array of favorite repository is hold by FavoriteViewController.

## Run

To run this example, you need `carthage update`.

In addition, you need to set `Github Personal Access Token` like this.

```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    // Override point for customization after application launch.

    ApiSession.shared.token = "Your Github Personal Access Token" // <- here

    //...
    return true
}
```

## Requirements

- Xcode 9 GM seed or later
- iOS 11 GM seed or later
- Swift 4 or later

## Other

This sample uses [GithubKitForSample](https://github.com/marty-suzuki/GithubKitForSample) that makes to create demo app easily.

## Author

marty-suzuki, s1180183@gmail.com

## License

iOSDesignPatternSamples is available under the MIT license. See the LICENSE file for more info.
