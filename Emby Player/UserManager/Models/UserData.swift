/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */
//
//  UserData.swift
//  Emby Player
//
//  Created by Mats Mollestad on 03/09/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//

import Foundation

struct UserData: Codable {
    let key: String?
    let unplayedItemCount: Int?
    let playbackPositionTicks: Int
    let playCount: Int
    let isFavorite: Bool
    let played: Bool

    enum CodingKeys: String, CodingKey {
        case key = "Key"
        case unplayedItemCount = "UnplayedItemCount"
        case playbackPositionTicks = "PlaybackPositionTicks"
        case playCount = "PlayCount"
        case isFavorite = "IsFavorite"
        case played = "Played"
    }
}
