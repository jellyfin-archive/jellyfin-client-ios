//
//  LatestLibraryStoreEmbyCatagoryFetcher.swift
//  Emby Player
//
//  Created by Mats Mollestad on 26/09/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//

import Foundation

class LatestLibraryStoreEmbyCatagoryFetcher: LibraryStoreFetchable {

    let catagory: MediaFolder

    init(catagory: MediaFolder) {
        self.catagory = catagory
    }

    func fetchItems(for user: User, completion: @escaping (FetcherResponse<[BaseItem]>) -> Void) {

        guard let server = ServerManager.currentServer else {
            completion(.failed(ServerManager.Errors.unableToConnectToServer))
            return
        }
        server.fetchLatestItems(in: catagory, forUserId: user.id) { (response) in
            completion(FetcherResponse(response: response))
        }
    }
}
