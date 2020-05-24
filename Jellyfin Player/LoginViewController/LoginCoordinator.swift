/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */
//
//  LoginCoordinator.swift
//  Jellyfin Player
//
//  Created by Mats Mollestad on 13/09/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//

import UIKit

class LoginCoordinator: LoginViewControllerDelegate {

    let presenter: UINavigationController

    var user: User?

    var loginViewController: LoginViewController?

    init(presenter: UINavigationController) {
        self.presenter = presenter
    }

    func start() {
        let loginViewController = LoginViewController(user: user)
        loginViewController.delegate = self
        self.loginViewController = loginViewController

        if user?.hasPassword == false {
            loginViewController.sendLoginRequest()
        } else {
            presenter.pushViewController(loginViewController, animated: true)
        }
    }

    func loginWasSuccessfull(for user: User?) {
        // Dismissing since the home screen will be presented under the login
        presenter.dismiss(animated: true, completion: nil)
    }
}
