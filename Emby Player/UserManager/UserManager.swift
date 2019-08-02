//
//  UserManager.swift
//  Emby Player
//
//  Created by Mats Mollestad on 26/08/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//

import Foundation
import UIKit
import KeychainSwift

protocol UserManaging {
    var embyAuthHeader: NetworkRequestHeaderValue { get }
    var embyTokenHeader: NetworkRequestHeaderValue { get }
    var deviceId: String { get }
}

class UserManager: UserManaging {

    enum Errors: Error {
        case unableToLogout
    }

    private struct Strings {
        static let accessTokenKey   = "AccessToken"
        static let userDataKey      = "UserDataKey"
    }

    static let shared = UserManager()
    private let keychain = KeychainSwift()

    /// The current logged in user
    var current: User? {
        get {
            guard let data = keychain.getData(Strings.userDataKey) else { return nil }
            return try? JSONDecoder().decode(User.self, from: data)
        }
        set {
            var userData: Data?
            if let user = newValue {
                userData = try? JSONEncoder().encode(user)
            }
            if let userData = userData {
                keychain.set(userData, forKey: Strings.userDataKey)
            } else {
                keychain.delete(Strings.userDataKey)
            }
        }
    }
    private var accessToken: String? {
        get {
            return keychain.get(Strings.accessTokenKey)
        }
        set {
            if let accessToken = newValue {
                keychain.set(accessToken, forKey: Strings.accessTokenKey)
            } else {
                keychain.delete(Strings.accessTokenKey)
            }
        }
    }

    var deviceId: String {
        UIDevice.current.identifierForVendor?.uuidString ?? "xxxx"
    }

    /// The emby auth header based on the current user
    /// This is needed for each network call to the library
    var embyAuthHeader: NetworkRequestHeaderValue {
        let userId = current == nil ? "" : "UserId: \(current!.id), "
        return NetworkRequestHeaderValue(header: "X-Emby-Authorization", value: "Emby \(userId)Client=\"Emby Player SPAM\", Device=\"iPhone\", DeviceId=\"\(deviceId)\", Version=\"1.0.0\"")
    }

    /// The emby token header needed for each network call to the library
    var embyTokenHeader: NetworkRequestHeaderValue {
        return NetworkRequestHeaderValue(header: "X-Emby-Token", value: accessToken ?? "")
    }

    /// Update the kychain to the logged in user
    func login(with authResult: AuthenticationResult) {
        current = authResult.user
        accessToken = authResult.accessToken
    }

    /// Deletes the values in the keychain
    func logout(completion: @escaping (NetworkRequesterResponse<Void>) -> Void) {

        guard let user = current else {
            completion(.failed(Errors.unableToLogout))
            return
        }

        ServerManager.currentServer?.logout(user) { [weak self] response in

            self?.current = nil
            self?.accessToken = nil

            switch response {
            case .success(_): completion( .success(()))
            case .failed(let error): completion( .failed(error))
            }
        }
    }
}
