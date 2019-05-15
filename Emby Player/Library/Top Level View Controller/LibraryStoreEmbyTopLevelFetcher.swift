//
//  LibraryStoreEmbyTopLevelFetcher.swift
//  Emby Player
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
