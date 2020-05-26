/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */
//
//  LibraryStoreOfflineItemFetcher.swift
//  Jellyfin Player
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
