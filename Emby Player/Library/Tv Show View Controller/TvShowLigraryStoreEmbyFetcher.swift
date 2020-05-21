/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */
//
//  TvShowLigraryStoreEmbyFetcher.swift
//  Emby Player
//
//  Created by Mats Mollestad on 26/09/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//

import Foundation

class TvShowLigraryStoreEmbyFetcher: TvShowLibraryStoreFetchable {

    let serieId: String

    init(serieId: String) {
        self.serieId = serieId
    }

    func fetchEpisodesFor(season: Int, completion: @escaping (FetcherResponse<[PlayableEpisode]>) -> Void) {

        guard let user = UserManager.shared.current,
            let server = ServerManager.currentServer else {
                completion(.failed(ServerManager.Errors.unableToConnectToServer))
                return
        }

        server.fetchEpisodesFor(serieId: serieId, userId: user.id) { (response) in
            switch response {
            case .failed(let error):    completion(.failed(error))
            case .success(let result):  completion(.success(result.items))
            }
        }
    }
}
