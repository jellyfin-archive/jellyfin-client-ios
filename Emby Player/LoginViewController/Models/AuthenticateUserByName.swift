//
//  AuthenticateUserByName.swift
//  Emby Player
//
//  Created by Mats Mollestad on 26/08/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//

import Foundation


struct AuthenticateUserByName: Codable {
    let username: String
    let passwordMd5: String?
    let password: String
    let pw: String
    
    enum CodingKeys: String, CodingKey {
        case username       = "Username"
        case passwordMd5    = "PasswordMd5"
        case password       = "Password"
        case pw             = "Pw"
    }
}
