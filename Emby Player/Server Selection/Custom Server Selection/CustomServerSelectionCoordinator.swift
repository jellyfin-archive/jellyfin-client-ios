/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */
//
//  CustomServerSelectionCoordinator.swift
//  Emby Player
//
//  Created by Mats Mollestad on 24/09/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//

import UIKit

class CustomServerSelectionCoordinator: Coordinating, CustomServerSelectionViewControllerDelegate {

    let presenter: UINavigationController

    lazy var selectionController = CustomServerSelectionViewController()

    init(presenter: UINavigationController) {
        self.presenter = presenter
    }

    func start() {
        selectionController.delegate = self
        selectionController.errorTextLabel.isHidden = true
        presenter.setViewControllers([selectionController], animated: false)
//        presenter.pushViewController(selectionController, animated: true)
    }

    func connectToServer(_ server: ServerConnection) {
        do {
            try ServerManager.shared.connect(to: server)
            UserManager.shared.logout { [weak self] response in
                self?.presenter.dismiss(animated: true, completion: nil)
            }
        } catch {
            selectionController.presentError(error)
        }
    }
}
