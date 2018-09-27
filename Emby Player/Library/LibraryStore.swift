//
//  LibraryStore.swift
//  Emby Player
//
//  Created by Mats Mollestad on 26/08/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//

import Foundation

protocol LibraryStoreFetchable: class {
    associatedtype LibraryItem
    func fetchItems(for user: User, completion: @escaping (FetcherResponse<[LibraryItem]>) -> Void)
}


class LibraryStore<Fetcher: LibraryStoreFetchable> {
    var items = [Fetcher.LibraryItem]()
    
    let fetcher: Fetcher
    init(fetcher: Fetcher) {
        self.fetcher = fetcher
    }
    
    
    func fetchItems(completion: @escaping (FetcherResponse<Void>) -> Void) {
        guard let user = UserManager.shared.current else { return }
        fetcher.fetchItems(for: user) { [weak self] (response) in
            var storeResponse: FetcherResponse<Void> = .success(())
            switch response {
            case .failed(let error): storeResponse = .failed(error)
            case .success(let items): self?.items = items
            }
            completion(storeResponse)
        }
    }
    
    var numberOfItems: Int {
        return items.count
    }
    
    func itemAt(index: Int) -> Fetcher.LibraryItem {
        return items[index]
    }
}
