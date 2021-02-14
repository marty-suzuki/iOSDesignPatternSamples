# iOSDesignPatternSamples

This is Github user search demo app which made by many variety of design patterns.

![](./Images/app.gif)

## Application Structure

![](./Images/structure.png)

- SearchViewController... Search Github user with query.
- UserRepositoryViewController... Show repositories of user who selected in SearchViewController.
- RepositoryViewController... Show a repository which selected in UserRepositoryViewController or FavoriteViewController. In addition, add / remove favorite repositories on memory.
- FavoriteViewController... Show favorite repositories which stored on memory.

## Design Patterns

- ### [MVC](https://github.com/marty-suzuki/iOSDesignPatternSamples/tree/mvc)
- ### [MVP](https://github.com/marty-suzuki/iOSDesignPatternSamples/tree/mvp)
- ### [MVVM](https://github.com/marty-suzuki/iOSDesignPatternSamples/tree/mvvm)
- ### [Flux](https://github.com/marty-suzuki/iOSDesignPatternSamples/tree/flux)

## Difference between A to B

|A / B|MVC|MVP|MVVM|Flux|
|:-:|:-:|:-:|:-:|:-:|
|MVC|-|[diff](https://github.com/marty-suzuki/iOSDesignPatternSamples/pull/1/files)|[diff](https://github.com/marty-suzuki/iOSDesignPatternSamples/pull/2/files)|[diff](https://github.com/marty-suzuki/iOSDesignPatternSamples/pull/3/files)|
|MVP|-|-|[diff](https://github.com/marty-suzuki/iOSDesignPatternSamples/pull/4/files)|[diff](https://github.com/marty-suzuki/iOSDesignPatternSamples/pull/5/files)|
|MVVM|-|-|-|[diff](https://github.com/marty-suzuki/iOSDesignPatternSamples/pull/6/files)|

You can compare differences like this.

![](./Images/diff.png)

## Run

You need to set `Github Personal Access Token` like this.

```swift
extension ApiSession {
    static let shared: ApiSession = {
        let token = "" // <- Your Github Personal Access Token
        return ApiSession(injectToken: { InjectableToken(token: token) })
    }()
}
```

## Requirements

- Xcode 12 or later
- iOS 13 or later
- Swift 5 or later

## Special Thanks

- [GithubKitForSample](https://github.com/marty-suzuki/GithubKitForSample)

## Author

marty-suzuki, s1180183@gmail.com

## License

iOSDesignPatternSamples is available under the MIT license. See the LICENSE file for more info.
