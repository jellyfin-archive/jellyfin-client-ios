//
//  PlayableOfflineManager.swift
//  Emby Player
//
//  Created by Mats Mollestad on 10/09/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//

import Foundation


class PlayableOfflineManager {
    
    enum Errors: Error {
        case noDownloadPathDefined
        case unableToEncodeItems
    }
    
    private struct Strings {
        static let downloadedItemsKey = "DownloadedItemsKey"
    }
    
    
    static let shared = PlayableOfflineManager()
    
    
    private var downloadedItems: [String : PlayableItem] {
        get {
            do {
                guard let data = UserDefaults.standard.data(forKey: Strings.downloadedItemsKey) else { throw Errors.unableToEncodeItems }
                return try JSONDecoder().decode([String : PlayableItem].self, from: data)
            } catch let error {
                print("Error:", error)
            }
            return [:]
        }
        set {
            do {
                let data = try JSONEncoder().encode(newValue)
                UserDefaults.standard.set(data, forKey: Strings.downloadedItemsKey)
            } catch let error {
                print("Error:", error)
            }
        }
    }
    
    func getItemWith(id: String) -> PlayableItem? {
        return downloadedItems[id]
    }
    
    func getAllItems() -> [PlayableItem] {
        return downloadedItems.map { $0.value }
    }
    
    func add(_ item: PlayableItem) throws {
        guard item.diskUrlPath != nil else { throw Errors.noDownloadPathDefined }
        downloadedItems[item.id] = item
    }
}
