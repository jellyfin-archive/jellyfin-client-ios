//
//  PlayableOfflineManager.swift
//  Emby Player
//
//  Created by Mats Mollestad on 10/09/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//

import Foundation


/// A class that has controll over all the saved items
class PlayableOfflineManager {
    
    enum Errors: Error {
        case noDownloadPathDefined
        case unableToEncodeItems
    }
    
    private struct Strings {
        static let downloadedItemsKey = "DownloadedItemsKey"
    }
    
    
    static let shared = PlayableOfflineManager()
    
    
    /// A dict containg all the saved items
    /// The key is the id
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
    
    func deleteItem(withId id: String) {
        guard let item = downloadedItems[id] else { return }
        guard let diskPath = item.diskUrlPath else { return }
        do {
            let documentDir = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            let fileUrl = documentDir.appendingPathComponent(diskPath)
            try FileManager.default.removeItem(at: fileUrl)
            downloadedItems[id] = nil
        } catch {
            print("Error removing file: \(error)")
        }
        
    }
    
    /// Returns an item with an associated id
    /// - parameter id: The id of the item
    /// - returns: A PlayableItem if found, otherwise nil
    func getItemWith(id: String) -> PlayableItem? {
        return downloadedItems[id]
    }
    
    /// - returns: All the saved items
    func getAllItems() -> [PlayableItem] {
        return downloadedItems.map { $0.value }
    }
    
    
    /// Saves an item to disk
    /// - parameter item: The item to save
    /// - throws: If the item do not have a .diskUrlPath variable a PlayableOfflineManager.Errors.noDownloadPathDefined will occure
    func add(_ item: PlayableItem) throws {
        guard item.diskUrlPath != nil else { throw Errors.noDownloadPathDefined }
        downloadedItems[item.id] = item
    }
}
