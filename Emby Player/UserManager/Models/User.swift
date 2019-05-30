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
