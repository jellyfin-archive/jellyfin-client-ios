//
//  UserListCoordinator.swift
//  Emby Player
//
//  Created by Mats Mollestad on 13/09/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//

import UIKit

class UserListCoordinator: Coordinating, UserListViewControllerDelegate {

    /// The controller to present from
    let presenter: UIViewController

    private lazy var userListFetcher            = UserListStoreEmbyPublicFetcher()

    private lazy var userListViewController     = UserListViewContentController(
        fetcher: self.userListFetcher
    )

    private lazy var contentController          = ContentStateViewController(
        contentController: self.userListViewController,   fetchMode: .onAppeare,   backgroundColor: .black
    )

    private lazy var navigationController       = UINavigationController(
        rootViewController: self.contentController
    )

    private lazy var loginCoordinator           = LoginCoordinator(
        presenter: self.navigationController
    )

    private lazy var embyConnectCoordinator     = EmbyLoginCoordinator(
        presenter: self.navigationController
    )

    init(presenter: UIViewController) {
        self.presenter = presenter
    }

    func start() {
        guard UserManager.shared.current == nil else { return }
        userListViewController.delegate = self
        contentController.leftBarButton = userListViewController.disconnectBarButton
        presenter.present(navigationController, animated: true) { [weak self] in
            self?.embyConnectCoordinator.start()
        }
    }

    func userWasSelected(_ user: User, from userListViewController: UserListViewContentController) {
        loginCoordinator.user = user
        loginCoordinator.start()
    }

    func disconnectFromServer() {
        ServerManager.shared.disconnect()
        EmbyConnectUserManager.shared.logout()
        embyConnectCoordinator.start()
    }
}
