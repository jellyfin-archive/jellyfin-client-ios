//
//  LocalItemCoordinator.swift
//  Emby Player
//
//  Created by Mats Mollestad on 13/09/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//

import UIKit


class LocalItemCoordinator: Coordinating, ItemViewControllerDelegate {
    
    let presenter: UINavigationController
    
    var item: BaseItem?
    
    lazy var itemFetcher = SingleItemOfflineFetcher(itemId: self.item?.id ?? "")
    lazy var itemController = ItemViewController(fetcher: self.itemFetcher)
    lazy var contentController = ContentStateViewController(contentController: self.itemController, fetchMode: .onInit, backgroundColor: .black)
    
    lazy var playerCoordinator = VideoPlayerCoordinator(presenter: self.itemController)
    
    init(presenter: UINavigationController, item: BaseItem? = nil) {
        self.presenter = presenter
        self.item = item
    }
    
    
    func start() {
        guard let item = item else { return }
        itemFetcher.itemId = item.id
        itemController.delegate = self
        presenter.pushViewController(contentController, animated: true)
    }
    
    
    func playItem(_ item: PlayableItem) {
        playerCoordinator.item = item
        playerCoordinator.start()
    }
    
    func downloadItem(_ item: PlayableItem) {
        
    }
}
