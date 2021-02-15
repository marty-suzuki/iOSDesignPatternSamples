//
//  SearchDispatcher.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2021/02/13.
//

import Combine
import Foundation
import GithubKit
import UIKit

final class SearchDispatcher {
    let selectedUser = PassthroughSubject<User, Never>()
    let updateLoadingView = PassthroughSubject<(UIView, Bool), Never>()
    let countString = PassthroughSubject<String, Never>()
    let users = PassthroughSubject<[User], Never>()
    let isFetchingUsers = PassthroughSubject<Bool, Never>()
    let keyboardWillShow = PassthroughSubject<UIKeyboardInfo, Never>()
    let keyboardWillHide = PassthroughSubject<UIKeyboardInfo, Never>()
    let accessTokenAlert = PassthroughSubject<ErrorMessage, Never>()
}
