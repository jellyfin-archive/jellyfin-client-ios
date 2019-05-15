//
//  TvShowLibraryViewController.swift
//  Emby Player
//
//  Created by Mats Mollestad on 29/08/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//

import UIKit

protocol TvShowLibraryStoreFetchable {
    func fetchEpisodesFor(season: Int, completion: @escaping (FetcherResponse<[PlayableEpisode]>) -> Void)
}

protocol TvShowLibraryViewControllerDelegate: class {
    func episodeWasSelected(_ episode: PlayableEpisode)
}

class TvShowLibraryStore {

    let fetcher: TvShowLibraryStoreFetchable
    var items = [PlayableEpisode]()

    init(fetcher: TvShowLibraryStoreFetchable) {
        self.fetcher = fetcher
    }

    func fetchEpisodes(completion: @escaping (FetcherResponse<Void>) -> Void) {
        fetcher.fetchEpisodesFor(season: 0) { [weak self] (response) in

            var retResponse: FetcherResponse<Void> = .success(())
            switch response {
            case .failed(let error): retResponse = .failed(error)
            case .success(let items): self?.items = items
            }
            completion(retResponse)
        }
    }
}

class TvShowLibraryViewController: UIViewController, ContentViewControlling {

    var contentViewController: UIViewController { return self }

    lazy var tableView: UITableView = self.setUpTableView()

    private let store: TvShowLibraryStore

    weak var delegate: TvShowLibraryViewControllerDelegate?

    init(fetcher: TvShowLibraryStoreFetchable) {
        store = TvShowLibraryStore(fetcher: fetcher)
        super.init(nibName: nil, bundle: nil)
        setUpViewController()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("Decoder not implemented")
    }

    private func setUpViewController() {
        view.addSubview(tableView)
        view.backgroundColor = .black
        tableView.fillSuperView()
    }

    private func setUpTableView() -> UITableView {
        let view = UITableView()
        view.delegate = self
        view.dataSource = self
        view.register(EpisodeTableViewCell.self)
        view.backgroundColor = .clear
        view.rowHeight = UITableView.automaticDimension
        view.estimatedRowHeight = 300
        return view
    }

    func fetchContent(completion: @escaping (FetcherResponse<Void>) -> Void) {
        store.fetchEpisodes(completion: completion)
    }
}

extension TvShowLibraryViewController: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return store.items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.cellForItem(at: indexPath, ofType: EpisodeTableViewCell.self)
        cell.episode = store.items[indexPath.row]
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = store.items[indexPath.row]

        delegate?.episodeWasSelected(item)

//        let itemFetcher = SingleItemStoreEmbyFetcher(itemId: item.id)
//        let itemController = ItemViewController(fetcher: itemFetcher)
//        let contentStateController = ContentStateViewController(contentController: itemController, fetchMode: .onAppeare, backgroundColor: .black)
//        navigationController?.pushViewController(contentStateController, animated: true)
//        contentStateController.fetchContent()
    }
}
