/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */
//
//  UserListStore.swift
//  Jellyfin Player
//
//  Created by Mats Mollestad on 26/08/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//

import Foundation

protocol UserListStoreFetchable {
    var isFetching: Bool { get }
    func fetchUserList(completion: @escaping (FetcherResponse<[User]>) -> Void) -> Operation?
}

class UserListStore {
    var users = [User]()
    let fetcher: UserListStoreFetchable

    init(fetcher: UserListStoreFetchable) {
        self.fetcher = fetcher
    }

    func refreshUsers(completion: @escaping (FetcherResponse<Void>) -> Void) {
        _ = fetcher.fetchUserList { [weak self] (response) in
            var storeResponse: FetcherResponse<Void> = .success(())
            switch response {
            case .success(let users): self?.users = users
            case .failed(let error): storeResponse = .failed(error)
            }
            completion(storeResponse)
        }
    }

    var numberOfUsers: Int { return users.count }

    var hasUsers: Bool { return numberOfUsers != 0 }

    func userAt(index: Int) -> User {
        return users[index]
    }
}
