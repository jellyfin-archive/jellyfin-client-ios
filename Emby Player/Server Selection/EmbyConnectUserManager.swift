//
//  EmbyConnectUserManager.swift
//  Emby Player
//
//  Created by Mats Mollestad on 25/09/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//

import Foundation

/// A class saving and keeping track of the status for Emby Connect
class EmbyConnectUserManager {

    private struct Strings {
        static let connectLoginKey = "connectLoginKey"
    }

    static let shared = EmbyConnectUserManager()

    /// A saved object that contains access token and some user info.
    var connectLogin: EmbyConnectLogin? {
        get {
            do {
                guard let data = UserDefaults.standard.data(forKey: Strings.connectLoginKey) else { return nil }
                return try JSONDecoder().decode(EmbyConnectLogin.self, from: data)
            } catch {
                return nil
            }
        }
        set {
            do {
                let data = newValue == nil ? nil : try JSONEncoder().encode(newValue)
                UserDefaults.standard.set(data, forKey: Strings.connectLoginKey)
            } catch {
                print("Error setting ServerManager.connectLogin: ", error)
            }
        }
    }

    /// Deletes all Emby Connect user info
    func logout() {
        connectLogin = nil
    }
}
