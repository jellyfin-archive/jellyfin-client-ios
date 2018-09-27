//
//  EmbyItemCoordiantor.swift
//  Emby Player
//
//  Created by Mats Mollestad on 13/09/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//

import UIKit


class EmbyItemCoordiantor: Coordinating, ItemViewControllerDelegate {
    
    let presenter: UINavigationController
    
    var itemId: String?
    
    lazy var itemFetcher = SingleItemStoreEmbyFetcher(itemId: self.itemId ?? "")
    lazy var itemController = ItemViewController(fetcher: self.itemFetcher)
    lazy var contentController = ContentStateViewController(contentController: self.itemController, fetchMode: .onInit, backgroundColor: .black)
    
    lazy var playerCoordinator = VideoPlayerCoordinator(presenter: self.contentController)
    
    init(presenter: UINavigationController, itemId: String? = nil) {
        self.presenter = presenter
        self.itemId = itemId
    }
    
    
    func start() {
        guard let itemId = itemId else { return }
        itemFetcher.itemId = itemId
        itemController.delegate = self
        presenter.pushViewController(contentController, animated: true)
    }
    
    
    func playItem(_ item: PlayableItem) {
        playerCoordinator.item = item
        playerCoordinator.start()
    }
    
    func downloadItem(_ item: PlayableItem) {
        ServerManager.currentServer?.downloadFile(item, delegate: itemController)
    }
}
