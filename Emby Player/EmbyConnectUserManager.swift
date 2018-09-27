//
//  EmbyConnectUserManager.swift
//  Emby Player
//
//  Created by Mats Mollestad on 25/09/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//

import Foundation



class EmbyConnectUserManager {
    
    private struct Strings {
        static let connectLoginKey = "connectLoginKey"
    }
    
    static let shared = EmbyConnectUserManager()
    
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
    
    func logout() {
        connectLogin = nil
    }
}
