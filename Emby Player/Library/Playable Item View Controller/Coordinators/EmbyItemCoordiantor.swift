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
    
    var downloadingItem: PlayableItem?
    
    init(presenter: UINavigationController, itemId: String? = nil) {
        self.presenter = presenter
        self.itemId = itemId
    }
    
    deinit {
        if let downloadingItem = downloadingItem {
            ItemDownloadManager.shared.remove(observer: self, forItemId: downloadingItem.id)
        }
    }
    
    func start() {
        guard let itemId = itemId else { return }
        itemFetcher.itemId = itemId
        itemController.delegate = self
        presenter.pushViewController(contentController, animated: true)
    }
    
    
    func playItem(_ item: PlayableItem) {
        guard let server = ServerManager.currentServer,
            let video = item.playableVideo(in: playerCoordinator.playerController, from: server) else { return }
        playerCoordinator.info = (item, video)
        playerCoordinator.start()
    }
    
    func downloadItem(_ item: PlayableItem) {
        do {
            downloadingItem = item
            try ServerManager.currentServer?.downloadFile(item)
            ItemDownloadManager.shared.add(self, forItemId: item.id)
            ItemDownloadManager.shared.add(itemController.actionsController, forItemId: item.id)
        } catch {
            print("Error downloading file: \(error)")
        }
    }
}


extension EmbyItemCoordiantor: DownloadManagerObserverable {
    
    func downloadWasCompleted(for downloadPath: DownloadManagerDownloadPath, response: FetcherResponse<DownloadManagerLocalPath>) {
        
        guard var item = downloadingItem else { return }
        ItemDownloadManager.shared.remove(observer: self, forItemId: item.id)
        
        switch response {
        case .success(let savePath):
            item.diskUrlPath = savePath
            try? PlayableOfflineManager.shared.add(item)
        case .failed(let error):
            print("Error downloading file: \(error)")
        }
    }
}
