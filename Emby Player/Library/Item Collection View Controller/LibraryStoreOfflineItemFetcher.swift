//
//  LibraryStoreOfflineItemFetcher.swift
//  Emby Player
//
//  Created by Mats Mollestad on 10/09/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//

import Foundation

class LibraryStoreOfflineItemFetcher: LibraryStoreFetchable {

    func fetchItems(for user: User, completion: @escaping (FetcherResponse<[BaseItem]>) -> Void) {
        completion(.success(PlayableOfflineManager.shared.getAllItems().map { BaseItem(item: $0) }))
    }
}
