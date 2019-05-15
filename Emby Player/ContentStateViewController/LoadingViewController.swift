//
//  LoadingViewController.swift
//  Emby Player
//
//  Created by Mats Mollestad on 26/09/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//

import UIKit

class LoadingViewController: UIViewController {

    lazy var loadingIndicator = UIActivityIndicatorView(style: .white)

    override func viewDidLoad() {
        view.backgroundColor = .clear
        view.addSubview(loadingIndicator)
        loadingIndicator.centerInSuperview()
        loadingIndicator.startAnimating()
    }
}
