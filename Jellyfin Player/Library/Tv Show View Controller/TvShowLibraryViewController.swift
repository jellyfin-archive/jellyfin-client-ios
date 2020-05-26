/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */
//
//  TvShowLibraryViewController.swift
//  Jellyfin Player
//
//  Created by Mats Mollestad on 29/08/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//

import UIKit

extension Array {
    func group<Value>(by keyPath: KeyPath<Element, Value>) -> [Value : [Element]] where Value: Hashable {
        self.reduce(into: [:]) {
            let key = $1[keyPath: keyPath]
            if let groupedElements = $0[key] {
                $0[key] = groupedElements + [$1]
            } else {
                $0[key] = [$1]
            }
        }
    }

    func group<Value>(by keyPath: KeyPath<Element, Value?>) -> [Value : [Element]] where Value: Hashable {
        self.reduce(into: [:]) {
            guard let key = $1[keyPath: keyPath] else { return }
            if let groupedElements = $0[key] {
                $0[key] = groupedElements + [$1]
            } else {
                $0[key] = [$1]
            }
        }
    }
}

protocol TvShowLibraryStoreFetchable {
    func fetchEpisodesFor(season: Int, completion: @escaping (FetcherResponse<[PlayableEpisode]>) -> Void)
}

protocol TvShowLibraryViewControllerDelegate: class {
    func episodeWasSelected(_ episode: PlayableEpisode)
}

class TvShowLibraryStore {

    let fetcher: TvShowLibraryStoreFetchable
    var items = [String : [PlayableEpisode]]()

    init(fetcher: TvShowLibraryStoreFetchable) {
        self.fetcher = fetcher
    }

    func fetchEpisodes(completion: @escaping (FetcherResponse<Void>) -> Void) {
        fetcher.fetchEpisodesFor(season: 0) { [weak self] (response) in

            var retResponse: FetcherResponse<Void> = .success(())
            switch response {
            case .failed(let error): retResponse = .failed(error)
            case .success(let items): self?.items = items.group(by: \.seasonName)
            }
            completion(retResponse)
        }
    }

    var numberOfSeasons: Int { items.keys.count }

    func season(at section: Int) -> String {
        items.keys.sorted()[section]
    }

    func episode(for indexPath: IndexPath) -> PlayableEpisode? {
        items[season(at: indexPath.section)]?[indexPath.row]
    }

    func numberOfEpisodeds(in section: Int) -> Int {
        items[season(at: section)]?.count ?? 0
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
        return store.numberOfSeasons
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return store.numberOfEpisodeds(in: section)
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return store.season(at: section)
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label = ViewBuilder.textLabel(font: .title2, text: store.season(at: section))
        let stackView = ViewBuilder.stackView(arrangedSubviews: [label],
                                              layoutMargins: UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16))
        let section = UIView()
        section.backgroundColor = UIColor(white: 0.05, alpha: 1)
        section.addSubview(stackView)
        stackView.fillSuperView()
        return section
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.cellForItem(at: indexPath, ofType: EpisodeTableViewCell.self)
        cell.episode = store.episode(for: indexPath)
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let item = store.episode(for: indexPath) {
            delegate?.episodeWasSelected(item)
        }
//        let itemFetcher = SingleItemStoreEmbyFetcher(itemId: item.id)
//        let itemController = ItemViewController(fetcher: itemFetcher)
//        let contentStateController = ContentStateViewController(contentController: itemController, fetchMode: .onAppeare, backgroundColor: .black)
//        navigationController?.pushViewController(contentStateController, animated: true)
//        contentStateController.fetchContent()
    }
}
