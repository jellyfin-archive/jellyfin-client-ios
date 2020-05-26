/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */
//
//  EmbyItemCoordiantor.swift
//  Jellyfin Player
//
//  Created by Mats Mollestad on 13/09/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//

import UIKit

class EmbyItemCoordiantor: Coordinating {

    let presenter: UINavigationController

    var itemId: String?

    lazy var itemFetcher = SingleItemStoreEmbyFetcher(itemId: self.itemId ?? "")
    lazy var itemController = ItemViewController(fetcher: self.itemFetcher)
    lazy var contentController = ContentStateViewController(contentController: self.itemController, fetchMode: .onLoad, backgroundColor: .black)

    lazy var playerCoordinator = VideoPlayerCoordinator(presenter: self.contentController)

    lazy var qualityController = QualitySelectorViewController()

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

    func presentQualityPicker(for item: PlayableIteming) {
        qualityController.delegate = self
        qualityController.item = item
        itemController.present(UINavigationController(rootViewController: qualityController), animated: true, completion: nil)
    }
}

extension EmbyItemCoordiantor: ItemViewControllerDelegate {

    func playItem(_ item: PlayableItem) {
        guard let server = ServerManager.currentServer,
            let video = item.playableVideo(in: playerCoordinator.playerController, from: server) else { return }
        playerCoordinator.info = (item, video)
        playerCoordinator.start()
    }

    func downloadItem(_ item: PlayableItem) {
        guard item.mediaSources.contains(where: { itemController.supportedContainer.supports(container: $0.container) }) else {
            presentQualityPicker(for: item)
            return
        }
        do {
            downloadingItem = item
            try ServerManager.currentServer?.downloadFile(item, supportedContainer: itemController.supportedContainer)
            ItemDownloadManager.shared.add(self, forItemId: item.id)
            ItemDownloadManager.shared.add(itemController.actionsController, forItemId: item.id)
            itemController.actionsController.updateDownloadStatus()
        } catch {
            print("Error downloading file: \(error)")
            itemController.actionsController.present(error)
        }
    }
}

extension EmbyItemCoordiantor: DownloadManagerObserverable {

    func downloadWasCompleted(for downloadPath: DownloadManagerDownloadPath, response: FetcherResponse<DownloadManagerLocalPath>) {
        guard let item = downloadingItem else { return }
        ItemDownloadManager.shared.remove(observer: self, forItemId: item.id)
    }
}

extension EmbyItemCoordiantor : QualitySelectorViewControllerDelegate {
    func didSelect(_ quality: QualitySelectorViewController.Quality, in picker: QualitySelectorViewController) {
        if let item = picker.item {
            SyncManager.shared.request(item, in: quality.bitrate)
        }
    }
}
