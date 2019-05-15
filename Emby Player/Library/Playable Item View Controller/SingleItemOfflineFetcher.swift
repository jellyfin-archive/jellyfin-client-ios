//
//  SingleItemOfflineFetcher.swift
//  Emby Player
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
