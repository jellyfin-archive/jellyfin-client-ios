/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */
//
//  UserListStoreEmbyPublicFetcher.swift
//  Emby Player
//
//  Created by Mats Mollestad on 26/09/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//

import Foundation

class UserListStoreEmbyPublicFetcher: UserListStoreFetchable {

    var isFetching: Bool = false

    func fetchUserList(completion: @escaping (FetcherResponse<[User]>) -> Void) -> Operation? {

        guard let server = ServerManager.currentServer else {
            completion(.failed(EmbyAPI.Errors.urlComponents))
            return nil
        }

        isFetching = true
        server.fetchPublicUsers { [weak self] (response) in
            switch response {
            case .success(let users): completion(.success(users))
            case .failed(let error): completion(.failed(error))
            }
            self?.isFetching = false
        }
        return nil
    }
}

class UserListStoreErrorFetcher: UserListStoreFetchable {
    var isFetching: Bool { return false }

    func fetchUserList(completion: @escaping (FetcherResponse<[User]>) -> Void) -> Operation? {
        completion(.failed( NetworkRequesterError.badRequest))
        return nil
    }
}
