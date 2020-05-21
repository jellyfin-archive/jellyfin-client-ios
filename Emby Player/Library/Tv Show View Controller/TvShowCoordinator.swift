/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */
//
//  TvShowCoordinator.swift
//  Emby Player
//
//  Created by Mats Mollestad on 13/09/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//

import UIKit

class TvShowCoordinator: Coordinating, TvShowLibraryViewControllerDelegate {

    let presenter: UINavigationController

    var tvShowController: TvShowLibraryViewController?

    var item: BaseItem?

    var coordinator: Coordinating?

    init(presenter: UINavigationController, item: BaseItem? = nil) {
        self.presenter = presenter
        self.item = item
    }

    func start() {
        guard let item = item else { return }
        let fetcher = TvShowLigraryStoreEmbyFetcher(serieId: item.id)
        tvShowController = TvShowLibraryViewController(fetcher: fetcher)
        tvShowController?.delegate = self
        tvShowController?.title = item.name
        let contentController = ContentStateViewController(contentController: tvShowController!, fetchMode: .onAppeare, backgroundColor: .black)
        presenter.pushViewController(contentController, animated: true)
    }

    func episodeWasSelected(_ episode: PlayableEpisode) {
        coordinator = EmbyItemCoordiantor(presenter: presenter, itemId: episode.id)
        coordinator?.start()
    }
}
