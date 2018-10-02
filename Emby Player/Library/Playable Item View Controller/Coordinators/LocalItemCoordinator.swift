//
//  LocalItemCoordinator.swift
//  Emby Player
//
//  Created by Mats Mollestad on 13/09/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//

import UIKit


/// A class coordinating a segue to view a localy stored video item
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
        contentController.title = item.name
        presenter.pushViewController(contentController, animated: true)
    }
    
    
    func playItem(_ item: PlayableItem) {
        do {
            let documentDir = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            guard let videoPath = item.diskUrlPath else { return }
            let videoUrl = documentDir.appendingPathComponent(videoPath)
            let video = Video(url: videoUrl)
            
            playerCoordinator.info = (item, video)
            playerCoordinator.start()
        } catch {
            print("Error playing local item: ", error)
        }
    }
    
    func downloadItem(_ item: PlayableItem) {
        PlayableOfflineManager.shared.deleteItem(withId: item.id)
    }
}