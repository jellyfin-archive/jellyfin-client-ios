/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */
//
//  User.swift
//  Emby Player
//
//  Created by Mats Mollestad on 26/08/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//

import Foundation

struct User: Codable {
    let name: String
    let id: String
    let serverId: String
    let serverName: String?
    let hasPassword: Bool

    enum CodingKeys: String, CodingKey {
        case name           = "Name"
        case id             = "Id"
        case serverId       = "ServerId"
        case serverName     = "ServerName"
        case hasPassword    = "HasPassword"
    }
}
