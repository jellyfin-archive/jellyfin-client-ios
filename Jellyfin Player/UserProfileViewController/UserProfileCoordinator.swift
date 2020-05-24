/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */
//
//  UserProfileCoordinator.swift
//  Jellyfin Player
//
//  Created by Mats Mollestad on 31/05/2019.
//  Copyright © 2019 Mats Mollestad. All rights reserved.
//

import UIKit

class UserProfileCoordinator: Coordinating, UserProfileViewControllerDelegate {

    let tabBarController: UITabBarController

    private lazy var userProfileViewController = UserProfileViewController()
    private lazy var navigationController = UINavigationController(rootViewController: self.userProfileViewController)

    private lazy var authCoordinator = UserListCoordinator(presenter: self.tabBarController)

    init(tabBarController: UITabBarController) {
        self.tabBarController = tabBarController
    }

    func start() {
        userProfileViewController.delegate = self
        var viewControllers = tabBarController.viewControllers ?? []
        viewControllers.append(navigationController)
        tabBarController.setViewControllers(viewControllers, animated: true)
        authCoordinator.start()
    }

    func userDidLogout(_ user: User) {
        UserManager.shared.logout { [weak self] response in
            DispatchQueue.main.async {
                self?.authCoordinator.start()
            }
        }
    }

    private func present(_ error: Error) {
        let alert = UIAlertController(title: "Ups! An error occured", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        navigationController.present(alert, animated: true, completion: nil)
    }
}
