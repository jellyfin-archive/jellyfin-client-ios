//
//  LocalLibraryCoordinator.swift
//  Emby Player
//
//  Created by Mats Mollestad on 13/09/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//

import UIKit

class LocalLibraryCoordinator: Coordinating, CatagoryLibraryViewControllerDelegate {

    let tabBarController: UITabBarController

    let fetcher = LibraryStoreOfflineItemFetcher()
    lazy var localContentViewController: CatagoryLibraryViewController<LibraryStoreOfflineItemFetcher> = self.setUpLoaclContentController()
    lazy var contentViewController = ContentStateViewController(contentController: self.localContentViewController, fetchMode: .onAppeare)
    lazy var navigationController = UINavigationController(rootViewController: self.contentViewController)

    lazy var ongoingBarButton: UIBarButtonItem = UIBarButtonItem(image: UIImage(named: "cloud-download"), style: .done, target: self, action: #selector(self.presentOngoingViewController))

    /// Used so the coordinator do not go out of memory
    var coordinator: Coordinating?

    init(tabBarController: UITabBarController) {
        self.tabBarController = tabBarController
    }

    private func setUpLoaclContentController() -> CatagoryLibraryViewController<LibraryStoreOfflineItemFetcher> {
        let controller = CatagoryLibraryViewController(fetcher: self.fetcher)
        controller.delegate = self
        controller.title = "Downloads"
        controller.tabBarItem.image = UIImage(named: "folder-download")
        return controller
    }

    func start() {
        var viewControllers = tabBarController.viewControllers ?? []
        viewControllers.append(navigationController)
        contentViewController.rightBarButton = ongoingBarButton
        tabBarController.setViewControllers(viewControllers, animated: true)
    }

    func itemWasSelected(_ item: BaseItem) {
        coordinator = LocalItemCoordinator(presenter: navigationController, item: item)
        coordinator?.start()
    }

    @objc
    func presentOngoingViewController() {
        coordinator = OngoingDownloadCoordinator(presenter: navigationController)
        coordinator?.start()
    }
}
