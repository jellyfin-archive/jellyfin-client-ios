//
//  UserManager.swift
//  Emby Player
//
//  Created by Mats Mollestad on 26/08/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//

import Foundation
import UIKit


protocol UserManaging {
    var embyAuthHeader: NetworkRequestHeaderValue { get }
    var embyTokenHeader: NetworkRequestHeaderValue { get }
}


class UserManager: UserManaging {
    
    private struct Strings {
        static let accessTokenKey   = "AccessToken"
        static let userDataKey      = "UserDataKey"
    }
    
    static let shared = UserManager()
    
    
    
    var current: User? {
        get {
            guard let data = UserDefaults.standard.data(forKey: Strings.userDataKey) else { return nil }
            return try? JSONDecoder().decode(User.self, from: data)
        }
        set {
            var userData: Data? = nil
            if let user = newValue {
                userData = try? JSONEncoder().encode(user)
            }
            UserDefaults.standard.set(userData, forKey: Strings.userDataKey)
        }
    }
    private var accessToken: String? {
        get {
            return UserDefaults.standard.string(forKey: Strings.accessTokenKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Strings.accessTokenKey)
        }
    }
    
    var embyAuthHeader: NetworkRequestHeaderValue {
        let userId = current == nil ? "" : "UserId: \(current!.id), "
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? "xxxx"
        return NetworkRequestHeaderValue(header: "X-Emby-Authorization", value: "Emby \(userId)Client=\"Emby Player SPAM\", Device=\"iPhone\", DeviceId=\"\(deviceId)\", Version=\"1.0.0\"")
    }
    var embyTokenHeader: NetworkRequestHeaderValue {
        return NetworkRequestHeaderValue(header: "X-Emby-Token", value: accessToken ?? "")
    }
    
    func loginWith(_ authResult: AuthenticationResult) {
        current = authResult.user
        accessToken = authResult.accessToken
    }
    
    func logout() {
        current = nil
        accessToken = nil
    }
}
