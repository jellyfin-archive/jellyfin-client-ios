//
//  SearchViewController.swift
//  Emby Player
//
//  Created by Mats Mollestad on 06/09/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//

import UIKit

protocol SearchViewControllerDelegate: class {
    func itemWasTapped(_ item: BaseItem)
}

class SearchViewController: UIViewController, ContentViewControlling, CatagoryLibraryViewControllerDelegate {

    var contentViewController: UIViewController { return self }

    var filterStore = LibraryStore(fetcher: LibraryStoreEmbyTopLevelFetcher())
    var mediaStores = [LibraryStore<FilterLibraryStoreEmbyCatagoryFetcher>]()

    var currentMediaStore: LibraryStore<FilterLibraryStoreEmbyCatagoryFetcher>? {
        if mediaStores.isEmpty {
            return nil
        }
        let currentIndex = searchController.searchBar.selectedScopeButtonIndex
        return mediaStores[currentIndex]
    }

    lazy var searchController = self.createSearchController()
    var contentController: CatagoryLibraryViewController<FilterLibraryStoreEmbyCatagoryFetcher>?
    var contentStateController: ContentStateViewController?

    weak var delegate: SearchViewControllerDelegate?

    init() {
        super.init(nibName: nil, bundle: nil)
        setUpViewController()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init?(coder aDecoder: NSCoder)")
    }

    private func setUpViewController() {
        title = "Search"
        tabBarItem.image = UIImage(named: "loupe")
    }

    override func viewWillAppear(_ animated: Bool) {
        if #available(iOS 11, *) {
            navigationItem.largeTitleDisplayMode = .always
            navigationController?.navigationBar.prefersLargeTitles = true
        }
        fetchContent { (_) in }
    }

    func fetchContent(completion: @escaping (FetcherResponse<Void>) -> Void) {
        filterStore.fetchItems { [weak self] (response) in
            completion(response)
            DispatchQueue.main.async {
                switch response {
                case .failed(let error): print("Error: ", error)
                case .success: self?.updateStores()
                }
            }
        }
    }

    private func updateStores() {
        mediaStores = filterStore.items.map {
            let fetcher = FilterLibraryStoreEmbyCatagoryFetcher(mediaFolder: $0)
            return LibraryStore(fetcher: fetcher)
        }
        searchController.searchBar.scopeButtonTitles = filterStore.items.map { $0.name }

        guard let mediaStore = mediaStores.first else { return }

        searchController.searchBar.selectedScopeButtonIndex = 0

        if contentController == nil {
            contentController = CatagoryLibraryViewController(store: mediaStore)
            contentController?.delegate = self
            contentStateController = ContentStateViewController(contentController: contentController!, fetchMode: .onAppeare, backgroundColor: .black)
            add(contentStateController!)
            contentStateController?.view.fillSuperViewToSafeArea()

            if #available(iOS 11, *) {
                navigationItem.searchController = searchController
                navigationItem.largeTitleDisplayMode = .always
            } else {
                contentController?.collectionViewHeader = searchController.searchBar
//                searchController.hidesNavigationBarDuringPresentation = false
            }
        } else {
            contentController?.update(mediaStore)
        }
    }

    private func createSearchController() -> UISearchController {
        let controller = UISearchController(searchResultsController: nil)
        controller.searchResultsUpdater = self
        controller.searchBar.placeholder = "Search here"
        controller.obscuresBackgroundDuringPresentation = false
        controller.dimsBackgroundDuringPresentation = false

        controller.searchBar.tintColor = .white
        controller.searchBar.barStyle = .black
        definesPresentationContext = true
        return controller
    }

    func itemWasSelected(_ item: BaseItem) {
        delegate?.itemWasTapped(item)
    }
}

extension SearchViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard currentMediaStore?.fetcher.nameFilter != searchController.searchBar.text else { return }
        if let store = currentMediaStore {
            contentController?.update(store)
        }
        currentMediaStore?.fetcher.nameFilter = searchController.searchBar.text
        contentStateController?.fetchContent()
        searchController.isActive = true
    }
}
