/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */
//
//  UserProfileStore.swift
//  Jellyfin Player
//
//  Created by Mats Mollestad on 31/05/2019.
//  Copyright © 2019 Mats Mollestad. All rights reserved.
//

import Foundation

protocol UserProfileStore {
    var current: User? { get }
    var profileImageURL: URL? { get }
}

extension UserManager: UserProfileStore {
    var profileImageURL: URL? {
        guard let user = current else { return nil }
        return ServerManager.currentServer?.profileImageUrl(for: user)
    }
}
