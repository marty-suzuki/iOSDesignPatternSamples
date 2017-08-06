//
//  UIKeyboardInfo.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2017/08/06.
//  Copyright © 2017年 marty-suzuki. All rights reserved.
//

import Foundation
import NoticeObserveKit

struct UIKeyboardInfo: NoticeUserInfoDecodable {
    let frame: CGRect
    let animationDuration: TimeInterval
    let animationCurve: UIViewAnimationOptions
    
    init?(info: [AnyHashable : Any]) {
        guard
            let frame = (info[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
            let duration = info[UIKeyboardAnimationDurationUserInfoKey] as? TimeInterval,
            let curve = info[UIKeyboardAnimationCurveUserInfoKey] as? UInt
        else { return nil }
        self.frame = frame
        self.animationDuration = duration
        self.animationCurve = UIViewAnimationOptions(rawValue: curve)
    }
}
