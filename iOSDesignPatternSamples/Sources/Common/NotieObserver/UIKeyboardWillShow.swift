//
//  UIKeyboardWillShow.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2017/08/06.
//  Copyright © 2017年 marty-suzuki. All rights reserved.
//

import Foundation
import NoticeObserveKit

struct UIKeyboardWillShow: NoticeType {
    typealias InfoType = UIKeyboardInfo
    static let name: Notification.Name = .UIKeyboardWillShow
}
