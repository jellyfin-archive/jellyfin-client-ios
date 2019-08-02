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

    static let shared = ItemDownloadManager()

    init() {
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
        return DownloadManager.shared.activeDownloads[urlPath]
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
        DownloadManager.shared.startDownload(from: video.url, to: savePath, with: headers)
        DownloadManager.shared.add(observer: self, forPath: video.url.path)
    }

    func cancleDownload(forItemId itemId: String) {
        guard let urlPath = downloadPathAssociation.filter({ $0.value == itemId }).first?.key else { return }
        DownloadManager.shared.cancleTask(withUrlPath: urlPath)
        activeDownloads[itemId] = nil
        downloadPathAssociation[urlPath] = nil
        saveActiceDownloads()
    }

    func add(_ observer: DownloadManagerObserverable, forItemId itemId: String) {
        guard let urlPath = downloadPathAssociation.filter({ $0.value == itemId }).first?.key else { return }
        DownloadManager.shared.add(observer: observer, forPath: urlPath)
    }

    func remove(observer: DownloadManagerObserverable, forItemId itemId: String) {
        guard let urlPath = downloadPathAssociation.filter({ $0.value == itemId }).first?.key else { return }
        DownloadManager.shared.remove(observer: observer, forPath: urlPath)
    }

    private func saveActiceDownloads() {
        let encoder = JSONEncoder()
        let data = try? encoder.encode(activeDownloads)
        let urlData = try? encoder.encode(downloadPathAssociation)
        UserDefaults.standard.set(data, forKey: Strings.activeDownloads)
        UserDefaults.standard.set(urlData, forKey: Strings.urlPathAlias)
    }

    private func loadActiveDownloads() {
        guard let data = UserDefaults.standard.data(forKey: Strings.activeDownloads),
            let downloads = try? JSONDecoder().decode(ItemDownloadingItems.self, from: data) else {
            return
        }
        for (key, value) in downloads {
            activeDownloads[key] = value
        }
        guard let urlData = UserDefaults.standard.data(forKey: Strings.urlPathAlias),
            let paths = try? JSONDecoder().decode(ItemDownloadingPathAlias.self, from: urlData) else {
                return
        }
        for (key, value) in paths {
            downloadPathAssociation[key] = value
        }
    }
}

extension ItemDownloadManager: DownloadManagerObserverable {

    func downloadWasCompleted(for downloadPath: DownloadManagerDownloadPath, response: FetcherResponse<DownloadManagerLocalPath>) {
        guard let itemId = downloadPathAssociation[downloadPath] else { return }
        guard var item = activeDownloads[itemId] else { return }
        
        activeDownloads[itemId] = nil
        downloadPathAssociation[downloadPath] = nil
        DownloadManager.shared.remove(observer: self, forPath: downloadPath)

        switch response {
        case .success(let savePath):
            item.diskUrlPath = savePath
            try? PlayableOfflineManager.shared.add(item)
        case .failed(let error):
            print("Error downloading file: \(error)")
        }
    }
}
