/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */
//
//  ItemDownloadManager.swift
//  Emby Player
//
//  Created by Mats Mollestad on 28/09/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//

import Foundation

/// A class used to coordinate the downloads of a PlayableItem object
class ItemDownloadManager {

    struct Strings {
        static let activeDownloads = "ItemActiveDownloads"
        static let urlPathAlias = "ItemUrlPathAlias"
    }

    enum Errors: LocalizedError {
        case unsupportedFormat

        var errorDescription: String? { return "Unsupported format" }
    }

    let downloadManager: DownloadManager
    let userDefaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    static let shared = ItemDownloadManager()

    init(downloadManager: DownloadManager = .shared, userDefaults: UserDefaults = .standard) {
        self.downloadManager = downloadManager
        self.userDefaults = userDefaults
        loadActiveDownloads()
        _ = DownloadManager.shared // Just initing the variable
    }

    typealias ItemDownloadingItems = [String: PlayableItem]
    typealias ItemDownloadingPathAlias = [DownloadManagerDownloadPath: String]

    private(set) var activeDownloads = ItemDownloadingItems()

    /// Containing the id associated with any url
    private var downloadPathAssociation = ItemDownloadingPathAlias()

    /// Returns all the active downloads
    /// - returns: All the active downloads
    func activeItems() -> [PlayableIteming] {
        return activeDownloads.map { $0.value }
    }

    /// Returns the progress for a given itemId
    /// - parameter itemId: The item id to get the progress for
    /// - returns: The download progress if it exists
    func progressFor(itemId: String) -> DownloadProgressable? {
        guard let urlPath = downloadPathAssociation.filter({ $0.value == itemId }).first?.key else { return nil }
        return downloadManager.activeDownloads[urlPath]
    }

    /// Starts a download of a given item
    /// - parameter item: The item to download
    /// - parameter video: The video of the item
    /// - parameter savePath: The path to save the item
    /// - parameter headers: The headers needed to download the file
    /// - throws: Errors.unsupprotedFormat if the video is a HLS stream
    func startDownload(for item: PlayableItem, with video: Video, to savePath: String, headers: NetworkRequesterHeader) throws {

        guard !video.isHLS else { throw Errors.unsupportedFormat }

        activeDownloads[item.id] = item
        downloadPathAssociation[video.url.path] = item.id
        saveActiceDownloads()
        downloadManager.startDownload(from: video.url, to: savePath, with: headers)
        downloadManager.add(observer: self, forPath: video.url.path)
    }

    func cancleDownload(forItemId itemId: String) {
        guard let urlPath = downloadPathAssociation.filter({ $0.value == itemId }).first?.key else { return }
        downloadManager.cancleTask(withUrlPath: urlPath)
        activeDownloads[itemId] = nil
        downloadPathAssociation[urlPath] = nil
        saveActiceDownloads()
    }

    func add(_ observer: DownloadManagerObserverable, forItemId itemId: String) {
        guard let urlPath = downloadPathAssociation.filter({ $0.value == itemId }).first?.key else { return }
        downloadManager.add(observer: observer, forPath: urlPath)
    }

    func remove(observer: DownloadManagerObserverable, forItemId itemId: String) {
        guard let urlPath = downloadPathAssociation.filter({ $0.value == itemId }).first?.key else { return }
        downloadManager.remove(observer: observer, forPath: urlPath)
    }

    private func saveActiceDownloads() {
        let data = try? encoder.encode(activeDownloads)
        let urlData = try? encoder.encode(downloadPathAssociation)
        userDefaults.set(data, forKey: Strings.activeDownloads)
        userDefaults.set(urlData, forKey: Strings.urlPathAlias)
    }

    private func loadActiveDownloads() {
        guard let data = userDefaults.data(forKey: Strings.activeDownloads),
            let downloads = try? decoder.decode(ItemDownloadingItems.self, from: data) else {
            return
        }
        for (key, value) in downloads {
            activeDownloads[key] = value
        }
        guard let urlData = userDefaults.data(forKey: Strings.urlPathAlias),
            let paths = try? decoder.decode(ItemDownloadingPathAlias.self, from: urlData) else {
                return
        }
        for (key, value) in paths {
            downloadPathAssociation[key] = value
        }
    }
}

extension ItemDownloadManager: DownloadManagerObserverable {

    private func removeItem(at downloadPath: DownloadManagerDownloadPath) {
        guard let itemId = downloadPathAssociation[downloadPath] else { return }

        activeDownloads[itemId] = nil
        downloadPathAssociation[downloadPath] = nil
        downloadManager.remove(observer: self, forPath: downloadPath)
        saveActiceDownloads()
    }

    func downloadWasCompleted(for downloadPath: DownloadManagerDownloadPath, response: FetcherResponse<DownloadManagerLocalPath>) {

        guard let itemId = downloadPathAssociation[downloadPath] else { return }
        guard var item = activeDownloads[itemId] else { return }

        removeItem(at: downloadPath)

        switch response {
        case .success(let savePath):
            item.diskUrlPath = savePath
            try? PlayableOfflineManager.shared.add(item)
        case .failed(let error):
            print("Error downloading file: \(error)")
        }
    }

    func downloadWasStopped(for downloadPath: DownloadManagerDownloadPath) {
        removeItem(at: downloadPath)
    }
}
