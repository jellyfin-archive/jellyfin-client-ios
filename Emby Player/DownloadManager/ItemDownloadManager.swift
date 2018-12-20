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
    
    enum Errors: LocalizedError {
        case unsupportedFormat
        
        var errorDescription: String? { return "Unsupported format" }
    }
    
    
    static let shared = ItemDownloadManager()
    
    var activeDownloads = [String : PlayableIteming]()
    
    /// Containing the id associated with any url
    private var downloadPathAssociation = [DownloadManagerDownloadPath : String]()
    
    
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
    func startDownload(for item: PlayableIteming, with video: Video, to savePath: String, headers: NetworkRequesterHeader) throws {
        
        guard !video.isHLS else { throw Errors.unsupportedFormat }
        
        activeDownloads[item.id] = item
        downloadPathAssociation[video.url.path] = item.id
        DownloadManager.shared.startDownload(from: video.url, to: savePath, with: headers)
        DownloadManager.shared.add(observer: self, forPath: video.url.path)
    }
    
    func cancleDownload(forItemId itemId: String) {
        guard let urlPath = downloadPathAssociation.filter({ $0.value == itemId }).first?.key else { return }
        DownloadManager.shared.cancleTask(withUrlPath: urlPath)
        activeDownloads[itemId] = nil
        downloadPathAssociation[urlPath] = nil
    }
    
    func add(_ observer: DownloadManagerObserverable, forItemId itemId: String)  {
        guard let urlPath = downloadPathAssociation.filter({ $0.value == itemId }).first?.key else { return }
        DownloadManager.shared.add(observer: observer, forPath: urlPath)
    }
    
    
    func remove(observer: DownloadManagerObserverable, forItemId itemId: String) {
        guard let urlPath = downloadPathAssociation.filter({ $0.value == itemId }).first?.key else { return }
        DownloadManager.shared.remove(observer: observer, forPath: urlPath)
    }
}

extension ItemDownloadManager: DownloadManagerObserverable {
    
    func downloadWasCompleted(for downloadPath: DownloadManagerDownloadPath, response: FetcherResponse<DownloadManagerLocalPath>) {
        guard let itemId = downloadPathAssociation[downloadPath] else { return }
        activeDownloads[itemId] = nil
        downloadPathAssociation[downloadPath] = nil
        DownloadManager.shared.remove(observer: self, forPath: downloadPath)
    }
}
