//
//  ServerManager.swift
//  Emby Player
//
//  Created by Mats Mollestad on 24/09/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//

import Foundation

struct EmbyConnectUser: Codable {
    let id: String
    let name: String
    let displayName: String
    let email: String

    enum CodingKeys: String, CodingKey {
        case id = "Id"
        case name = "Name"
        case displayName = "DisplayName"
        case email = "Email"
    }
}

struct EmbyConnectLogin: Codable {
    let accessToken: String
    let user: EmbyConnectUser

    enum CodingKeys: String, CodingKey {
        case accessToken = "AccessToken"
        case user = "User"
    }
}

/// A class that has controll over which emby server to use
class ServerManager {

    private struct Strings {
        static let currentServerConnection      = "currentServerConnectionKey"
        static let unableToConnectToServerError = "Unable to connect to server. Check that the url is correct."
    }

    enum Errors: LocalizedError {
        case unableToConnectToServer

        var errorDescription: String? { return Strings.unableToConnectToServerError }
    }

    static let shared = ServerManager()
    static var currentServer: EmbyAPI? { return shared.currentServer }

    var servers = [EmbyAPI]()
    var isConnected: Bool {
        return currentServer != nil
    }

    init() {
        if let server = currentServerConnection {
            try? connect(to: server)
        }
    }

    /// A saved instance of a ServerConnection
    var currentServerConnection: ServerConnection? {
        get {
            do {
                guard let data = UserDefaults.standard.data(forKey: Strings.currentServerConnection) else { return nil }
                return try JSONDecoder().decode(ServerConnection.self, from: data)
            } catch {
                print("Error decoding connected server data: ", error)
            }
            return nil
        }
        set {
            do {
                let data = newValue == nil ? nil : try JSONEncoder().encode(newValue)
                UserDefaults.standard.set(data, forKey: Strings.currentServerConnection)
            } catch {
                print("Error setting current server connection: ", error)
            }
        }
    }

    /// The current server that is connected
    var currentServer: EmbyAPI?

    /// Connects to a server
    /// - parameter server: The server to connect to
    /// - throws: if the server connection is not a valid url this will throw a ServerManager.Errors.unableToConnectToServer error
    func connect(to server: ServerConnection) throws {
        let lowercaseAddress = server.ipAddress.lowercased()
        let urlString = (lowercaseAddress.hasPrefix("http") ? "" : "https://") + lowercaseAddress + ":\(server.port)/"
        guard let url = URL(string: urlString) else { throw Errors.unableToConnectToServer }
        currentServerConnection = server
        currentServer = EmbyAPI(baseUrl: url)
    }

    /// Deletes all saved data and cached data
    func disconnect() {
        currentServer = nil
        currentServerConnection = nil
    }
}
