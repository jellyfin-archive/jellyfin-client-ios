//
//  TopLevelCoordinator.swift
//  Emby Player
//
//  Created by Mats Mollestad on 13/09/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//

import UIKit

class TopLevelCoordinator: Coordinating, TopLevelLibraryViewControllerDelegate {

    lazy var topLevelFetcher = LibraryStoreEmbyTopLevelFetcher()
    lazy var topLevelViewController = TopLevelLibraryViewController(fetcher: self.topLevelFetcher)
    lazy var contentViewController = ContentStateViewController(contentController: self.topLevelViewController, fetchMode: .onAppeare)
    lazy var navigationController = UINavigationController(rootViewController: self.contentViewController)

//    lazy var authCoordinator = UserListCoordinator(presenter: self.navigationController)

    var coordinator: Coordinating?

    let tabBarController: UITabBarController

    init(tabBarController: UITabBarController) {
        self.tabBarController = tabBarController
    }

    func start() {
        topLevelViewController.delegate = self
        var viewControllers = tabBarController.viewControllers ?? []
        viewControllers.append(navigationController)
        tabBarController.setViewControllers(viewControllers, animated: true)
    }

    func folderWasSelected(_ folder: MediaFolder) {
        coordinator = MediaLibraryCoordinator(presenter: navigationController, mediaFolder: folder)
        coordinator?.start()
    }

    func userDidLogout() {
//        authCoordinator.start()
    }

    func itemWasSelected(_ item: BaseItem) {
        if item.type == "Series" {
            coordinator = TvShowCoordinator(presenter: navigationController, item: item)
        } else if item.isFolder == true {
            let mediaFoler = MediaFolder(item: item)
            coordinator = MediaLibraryCoordinator(presenter: navigationController, mediaFolder: mediaFoler)
        } else {
            coordinator = EmbyItemCoordiantor(presenter: navigationController, itemId: item.id)
        }

        coordinator?.start()
    }
}
