/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */
//
//  LibraryStoreEmbyTopLevelFetcher.swift
//  Jellyfin Player
//
//  Created by Mats Mollestad on 26/09/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//

import Foundation

class LibraryStoreEmbyTopLevelFetcher: LibraryStoreFetchable {
    func fetchItems(for user: User, completion: @escaping (FetcherResponse<[MediaFolder]>) -> Void) {

        guard let server = ServerManager.currentServer else {
            completion(.failed(ServerManager.Errors.unableToConnectToServer))
            return
        }

        server.fetchLibraryTopCatagoriesFor(userId: user.id) { (response: NetworkRequesterResponse<QueryResult>) in
            switch response {
            case .success(let result):  completion(.success(result.items))
            case .failed(let error):    completion(.failed(error))
            }
        }
    }
}
