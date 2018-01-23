# iOSDesignPatternSamples (MVVM)

This is Github user search demo app that made with MVVM design pattern.

## Application Structure

![](./Images/structure.png)

## ViewControllers

### [SearchViewController](./iOSDesignPatternSamples/Sources/UI/Search/SearchViewController.swift)
Search Github user and show user result list

![](./Images/search.png)

- [SearchViewModel](./iOSDesignPatternSamples/Sources/UI/Search/SearchViewModel.swift)
- [SearchViewDataSource](./iOSDesignPatternSamples/Sources/UI/Search/SearchViewDataSource.swift) <- Adapt UITableViewDataSource and UITableViewDelegate

### [FavoriteViewController](./iOSDesignPatternSamples/Sources/UI/Favorite/FavoriteViewController.swift)
Show local on memory favorite repositories

![](./Images/favorite.png)

- [FavoriteViewModel](./iOSDesignPatternSamples/Sources/UI/Favorite/FavoriteViewModel.swift)
- [FavoriteViewDataSource](./iOSDesignPatternSamples/Sources/UI/Favorite/FavoriteViewDataSource.swift) <- Adapt UITableViewDataSource and UITableViewDelegate

### [UserRepositoryViewController](./iOSDesignPatternSamples/Sources/UI/UserRepository/UserRepositoryViewController.swift)
Show Github user's repositories

![](./Images/user_repository.png)

- [UserRepositoryViewModel](./iOSDesignPatternSamples/Sources/UI/UserRepository/UserRepositoryViewModel.swift)
- [UserRepositoryViewDataSource](./iOSDesignPatternSamples/Sources/UI/UserRepository/UserRepositoryViewDataSource.swift) <- Adapt UITableViewDataSource and UITableViewDelegate

### [RepositoryViewController](./iOSDesignPatternSamples/Sources/UI/Repository/RepositoryViewController.swift)
Show a repository and add / remove local on memory favorites

![](./Images/repository.png)

- [RepositoryViewModel](./iOSDesignPatternSamples/Sources/UI/Repository/RepositoryViewModel.swift)

## How to add / remove favorites

You can add / remove favorite repositories in RepositoryViewController, but an Array of favorite repository is hold by FavoriteViewController.

## Run

To run this example, you need `carthage update`.

In addition, you need to set `Github Personal Access Token` like this.

```swift
extension ApiSession {
    static let shared: ApiSession = {
        let token = "" // <- Your Github Personal Access Token
        return ApiSession(injectToken: { InjectableToken(token: token) })
    }()
}
```

## Requirements

- Xcode 9.2 or later
- iOS 11 or later
- Swift 4 or later

## Special Thanks

- [RxSwift](https://github.com/ReactiveX/RxSwift)
- [Nuke](https://github.com/kean/Nuke)
- [SwiftIconFont](https://github.com/0x73/SwiftIconFont)
- [FluxCapacitor](https://github.com/marty-suzuki/FluxCapacitor)
- [GithubKitForSample](https://github.com/marty-suzuki/GithubKitForSample)
- [NoticeObserveKit](https://github.com/marty-suzuki/NoticeObserveKit)

## Author

marty-suzuki, s1180183@gmail.com

## License

iOSDesignPatternSamples is available under the MIT license. See the LICENSE file for more info.
