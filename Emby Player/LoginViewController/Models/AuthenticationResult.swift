//
//  AuthenticationResult.swift
//  Emby Player
//
//  Created by Mats Mollestad on 26/08/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//

import Foundation


struct AuthenticationResult: Codable {
    let user: User
    let accessToken: String
    let serverId: String
    
    enum CodingKeys: String, CodingKey {
        case user           = "User"
        case accessToken    = "AccessToken"
        case serverId       = "ServerId"
    }
}
