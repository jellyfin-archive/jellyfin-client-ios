/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */
//
//  ApplicationCoordinator.swift
//  Emby Player
//
//  Created by Mats Mollestad on 13/09/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//

import UIKit

/// Coordinates all the view controllers that should be presented at startup
class ApplicationCoordinator: Coordinating {

    let window: UIWindow

    private let tabBarController            = UITabBarController(nibName: nil, bundle: nil)

    private lazy var topLevelCoordinator    = TopLevelCoordinator(tabBarController: self.tabBarController)
    private lazy var searchCoordinator      = SearchCoordinator(tabBarController: self.tabBarController)
    private lazy var downloadCoordinator    = LocalLibraryCoordinator(tabBarController: self.tabBarController)
    private lazy var profileCoordinator     = UserProfileCoordinator(tabBarController: self.tabBarController)

    init(window: UIWindow) {
        self.window = window
    }

    func start() {
        window.rootViewController = tabBarController
        window.makeKeyAndVisible()
        _ = ItemDownloadManager.shared // initing the download manager
        downloadCoordinator.start()
        topLevelCoordinator.start()
        searchCoordinator.start()
        profileCoordinator.start()
        tabBarController.selectedIndex = 1
    }
}
