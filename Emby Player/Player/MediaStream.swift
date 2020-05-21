/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */
//
//  MediaStream.swift
//  Emby Player
//
//  Created by Mats Mollestad on 30/08/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//

import Foundation

struct MediaStream: Codable {
    let displayTitle: String?
    let bitRate: Int?
    let aspectRatio: String?
    let profile: String?
    let type: String
    let index: Int?
    let codec: String

    enum CodingKeys: String, CodingKey {
        case displayTitle   = "DisplayTitle"
        case bitRate        = "BitRate"
        case aspectRatio    = "AspectRatio"
        case profile        = "Profile"
        case type           = "Type"
        case index          = "Index"
        case codec          = "Codec"
    }
}
