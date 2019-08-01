//
//  EmbyLoginCoordinator.swift
//  Emby Player
//
//  Created by Mats Mollestad on 24/09/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//

import UIKit

class EmbyLoginCoordinator: Coordinating, EmbyLoginViewControllerDelegate {

    enum Errors: LocalizedError {
        case notAbleToUserEmbyConnect

        var errorDescription: String? {
            return "This version do not support Emby Connect login, therfore use a custom server connection."
        }
    }

    let presenter: UIViewController

    lazy var loginController            = EmbyLoginViewController()
    lazy var navigationController       = UINavigationController(rootViewController: self.loginController)
    lazy var customServerCoordinator    = CustomServerSelectionCoordinator(presenter: self.navigationController)

    init(presenter: UIViewController) {
        self.presenter = presenter
    }

    func start() {

        guard ServerManager.currentServer == nil, EmbyConnectUserManager.shared.connectLogin == nil else { return }
        navigationController.popToRootViewController(animated: false)
        loginController.delegate = self
        navigationController.modalPresentationStyle = .fullScreen
        presenter.present(navigationController, animated: true) { [weak self] in
            self?.connectToCustomServer()
        }
    }

    func connectToCustomServer() {
        customServerCoordinator.start()
    }

    func willLogin(with request: LoginRequest) {

        loginController.presentError(Errors.notAbleToUserEmbyConnect)

        // FIXME: - Make it possible to user emby connect
//        EmbyConnectAPI.shared.login(with: request) { [weak self] (response) in
//            switch response {
//
//            case .success(let login):
//                EmbyConnectUserManager.shared.connectLogin = login
//                self?.navigationController.dismiss(animated: true, completion: nil)
//
//            case .failed(let error):
//                self?.loginController.presentError(error)
//            }
//        }
    }
}
