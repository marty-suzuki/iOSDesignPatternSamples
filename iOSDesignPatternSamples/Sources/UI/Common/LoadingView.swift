//
//  LoadingView.swift
//  iOSDesignPatternSamples
//
//  Created by marty-suzuki on 2017/08/06.
//  Copyright © 2017年 marty-suzuki. All rights reserved.
//

import UIKit
import GithubKit

final class LoadingView: UIView {
    static let defaultHeight: CGFloat = 44
    
    private let activityIndicator: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .medium)
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.widthAnchor.constraint(equalToConstant: 20),
            view.heightAnchor.constraint(equalTo: view.widthAnchor)
        ])
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            activityIndicator.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            activityIndicator.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var isLoading: Bool = false {
        didSet {
            DispatchQueue.main.async {
                self.activityIndicator.isHidden = !self.isLoading
                if self.isLoading {
                    self.activityIndicator.startAnimating()
                } else {
                    self.activityIndicator.stopAnimating()
                }
            }
        }
    }
    
    func add(to view: UIView) {
        removeFromSuperview()
        translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(self)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: topAnchor),
            view.leftAnchor.constraint(equalTo: leftAnchor),
            view.rightAnchor.constraint(equalTo: rightAnchor),
            view.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}

extension LoadingView: ReusableView {
    func prepareForReuse() {}
    func configure(with configuration: Never) {}
}
