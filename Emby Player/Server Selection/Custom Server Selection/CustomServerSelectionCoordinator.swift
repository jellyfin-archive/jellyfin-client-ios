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
        presenter.pushViewController(selectionController, animated: true)
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
