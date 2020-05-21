/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */
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
