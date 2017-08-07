# iOSDesignPatternSamples (MVC)

This is Github user search demo app that made with MVC design pattern.

## Application Structure

![](./Images/structure.png)

## ViewControllers

- [SearchViewController](./iOSDesignPatternSamples/Sources/UI/Search/SearchViewController.swift) -> Search Github user and show user result list
- [FavoriteViewController](./iOSDesignPatternSamples/Sources/UI/Favorite/FavoriteViewController.swift) -> Show local on memory favorite repositories
- [UserRepositoryViewController](./iOSDesignPatternSamples/Sources/UI/UserRepository/UserRepositoryViewController.swift) -> Show Github user's repositories
- [RepositoryViewController](./iOSDesignPatternSamples/Sources/UI/Repository/RepositoryViewController.swift) -> Show a repository and add / remove local on memory favorites

## How to add / remove favorites

You can add / remove favorite repositories in RepositoryViewController, but an Array of favorite repository is hold by FavoriteViewController.

## Other

This sample uses [GithubKitForSample](https://github.com/marty-suzuki/GithubKitForSample) that makes to create demo app easily.

## Author

marty-suzuki, s1180183@gmail.com

## License

iOSDesignPatternSamples is available under the MIT license. See the LICENSE file for more info.
