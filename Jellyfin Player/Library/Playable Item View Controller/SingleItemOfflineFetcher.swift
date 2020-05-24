/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */
//
//  SingleItemOfflineFetcher.swift
//  Jellyfin Player
//
//  Created by Mats Mollestad on 10/09/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//

import Foundation

class SingleItemOfflineFetcher: SingleItemStoreFetchable {

    enum Errors: Error {
        case unableToFetchLocalItem
    }

    var itemId: String

    init(itemId: String) {
        self.itemId = itemId
    }

    func fetchItem(completion: @escaping (FetcherResponse<PlayableItem>) -> Void) {
        if let item = PlayableOfflineManager.shared.getItemWith(id: itemId) {
            completion(.success(item))
        } else {
            completion(.failed(Errors.unableToFetchLocalItem))
        }
    }
}
