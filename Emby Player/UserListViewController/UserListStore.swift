//
//  UserListStore.swift
//  Emby Player
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
    
    func userAt(index: Int) -> User {
        return users[index]
    }
}
