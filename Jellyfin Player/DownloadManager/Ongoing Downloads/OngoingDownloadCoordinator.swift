/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */
//
//  OngoingDownloadCoordinator.swift
//  Jellyfin Player
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
