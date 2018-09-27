//
//  ApplicationCoordinator.swift
//  Emby Player
//
//  Created by Mats Mollestad on 13/09/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//

import UIKit


class ApplicationCoordinator: Coordinating {
    
    let window: UIWindow

    private let tabBarController = UITabBarController(nibName: nil, bundle: nil)
    
    private lazy var topLevelCoordinator = TopLevelCoordinator(tabBarController: self.tabBarController)
    private lazy var searchCoordinator = SearchCoordinator(tabBarController: self.tabBarController)
    private lazy var downloadCoordinator = LocalLibraryCoordinator(tabBarController: self.tabBarController)
    
    private lazy var authCoordinator = UserListCoordinator(presenter: self.tabBarController)
    
    init(window: UIWindow) {
        self.window = window
        topLevelCoordinator.start()
        searchCoordinator.start()
        downloadCoordinator.start()
    }
    
    
    func start() {
        window.rootViewController = tabBarController
        window.makeKeyAndVisible()
        authCoordinator.start()
    }
}
