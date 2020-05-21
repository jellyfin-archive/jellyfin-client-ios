/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */
//
//  FilterLibraryStoreEmbyCatagoryFetcher.swift
//  Emby Player
//
//  Created by Mats Mollestad on 06/09/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//

import Foundation

class FilterLibraryStoreEmbyCatagoryFetcher: LibraryStoreFetchable {

    let mediaFolder: MediaFolder
    var nameFilter: String?

    init(mediaFolder: MediaFolder) {
        self.mediaFolder = mediaFolder
    }

    func fetchItems(for user: User, completion: @escaping (FetcherResponse<[BaseItem]>) -> Void) {

        guard let id = UserManager.shared.current?.id else {
            completion(.failed(NSError(domain: "FilterLibraryStoreEmbyCatagoryFetcher Missing User Id", code: 0, userInfo: nil)))
            return
        }
        guard let server = ServerManager.currentServer else {
            completion(.failed(ServerManager.Errors.unableToConnectToServer))
            return
        }

        server.fetchItemsIn(catagory: mediaFolder, forUserId: id, filter: nameFilter) { (respose) in
            completion(FetcherResponse(response: respose))
        }
    }
}
