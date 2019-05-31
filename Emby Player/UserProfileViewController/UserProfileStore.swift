//
//  UserProfileStore.swift
//  Emby Player
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
