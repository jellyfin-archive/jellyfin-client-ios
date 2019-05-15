//
//  OngoingDownloadCoordinator.swift
//  Emby Player
//
//  Created by Mats Mollestad on 28/09/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//

import UIKit

class OngoingDownloadCoordinator: Coordinating {

    let presenter: UINavigationController

    lazy var ongoingViewController = OngoingDownloadsViewController()

    init(presenter: UINavigationController) {
        self.presenter = presenter
    }

    func start() {
        presenter.pushViewController(ongoingViewController, animated: true)
    }
}
