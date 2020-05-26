/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */
//
//  EmbyAPI.swift
//  Jellyfin Player
//
//  Created by Mats Mollestad on 30/08/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//

import Foundation

enum PlayMethode: String, Codable {
    case transcode      = "Transcode"
    case directStream   = "DirectStream"
    case directPlay     = "DirectPlay"
}

enum RepeatMode: String, Codable {
    case repeatNone     = "RepeatNone"
    case repeatAll      = "RepeatAll"
    case repeatOne      = "RepeatOne"
}

enum MediaType: String, Codable {
    case audio          = "Audio"
    case video          = "Video"
}

struct PlaybackStart: Codable {
    let queueableMediaTypes: [MediaType]
    let canSeek: Bool?
    let items: [BaseItem]
    let itemId: String
    let mediaSourceId: String
    let audioStreamIndex: Int?
    let subtitleStreamIndex: Int?
    let isPaused: Bool?
    let isMuted: Bool?
    let positionTicks: Int?
    let volumeLevel: Int?
    let playMethode: PlayMethode
    let liveStreamId: String
    let playSessionId: String

    enum CodingKeys: String, CodingKey {
        case queueableMediaTypes    = "QueueableMediaTypes"
        case canSeek                = "CanSeek"
        case items                  = "Items"
        case itemId                 = "ItemId"
        case mediaSourceId          = "MediaSourceId"
        case audioStreamIndex       = "AudioStreamIndex"
        case subtitleStreamIndex    = "SubtitleStreamIndex"
        case isPaused               = "IsPaused"
        case isMuted                = "IsMuted"
        case positionTicks          = "PositionTicks"
        case volumeLevel            = "VolumeLevel"
        case playMethode            = "PlayMethode"
        case liveStreamId           = "LiveStreamId"
        case playSessionId          = "PlaySessionId"
    }
}

/// An object used to make calls to the Emby Librariy
class EmbyAPI {

    struct NoContent: Codable {}

    enum Errors: LocalizedError {
        case urlComponents
        case dataDecoding
        case unsupportedFile(String)

        var errorDescription: String? {
            switch self {
            case .urlComponents: return "Invalid url"
            case .dataDecoding: return "Not able to decode content"
            case .unsupportedFile(let file): return "Unsupported file: \(file)"
            }
        }
    }

    let baseUrl: URL
    var userManager: UserManaging = UserManager.shared

    init(baseUrl: URL) {
        self.baseUrl = baseUrl
    }

    func startPlaybackSession(for item: PlayableIteming, in player: SupportedContainerController) -> Video? {

        guard let video = item.playableVideo(in: player, from: self) else { return nil }

//        let sessionUrl = baseUrl.appendingPathComponent("emby/Sessions/Playing")
//        let session = item.session()
//
//        var header = NetworkRequester.defaultHeader
//        header.insert(userManager.embyAuthHeader)
//        header.insert(userManager.embyTokenHeader)
//
//        NetworkRequester().post(at: sessionUrl, header: header, body: session) { (response: NetworkRequesterResponse<Int?>) in
//            switch response {
//            case .failed(let error):    print("Error:", error)
//            case .success(_):           print("Success")
//            }
//        }

        return video
    }

    func imageUrl(of type: ImageType, itemId: String) -> URL {
        return baseUrl.appendingPathComponent("emby/Items/\(itemId)/Images/\(type.rawValue)")
    }

    func markItemAsWatched(_ item: PlayableIteming, userId: String) {

        let urlPath = baseUrl.appendingPathComponent("emby/Users/\(userId)/PlayedItems/\(item.id)")

        var header = NetworkRequester.defaultHeader
        header.insert(userManager.embyAuthHeader)
        header.insert(userManager.embyTokenHeader)

        let body: String? = nil

        NetworkRequester().post(at: urlPath, header: header, body: body) { (response: NetworkRequesterResponse<String?>) in
            switch response {
            case .failed(let error):    print("Error:", error)
            case .success:           print("Success")
            }
        }
    }

    func profileImageUrl(for user: User) -> URL {
        return baseUrl.appendingPathComponent("emby/Users/\(user.id)/Images/Primary")
    }

    func fetchItemsIn(catagory: MediaFolder, forUserId userId: String, filter: String? = nil, completion: @escaping (NetworkRequesterResponse<[BaseItem]>) -> Void) {

        let urlPath = baseUrl.appendingPathComponent("emby/Users/\(userId)/Items")

        guard var urlComponents = URLComponents(url: urlPath, resolvingAgainstBaseURL: true) else {
            completion(.failed(Errors.urlComponents))
            return
        }
        urlComponents.queryItems = [URLQueryItem(name: "ParentId", value: catagory.id)]

        if let filter = filter {
            urlComponents.queryItems! += [URLQueryItem(name: "NameStartsWith", value: filter)]
        }

        guard let url = urlComponents.url else {
            completion(.failed(Errors.urlComponents))
            return
        }

        var headers = NetworkRequester.defaultHeader
        headers.insert(userManager.embyTokenHeader)
        headers.insert(userManager.embyAuthHeader)

        NetworkRequester().get(at: url, header: headers) { (response: NetworkRequesterResponse<QueryResult<BaseItem>>) in
            switch response {
            case .success(let result): completion(.success(result.items))
            case .failed(let error): completion(.failed(error))
            }
        }
    }

    func fetchSeasonsFor(serieId: String, userId: String, completion: @escaping (NetworkRequesterResponse<QueryResult<BaseItem>>) -> Void) {

        let urlPath = baseUrl.appendingPathComponent("emby/Shows/\(serieId)/Seasons")

        guard var urlComponents = URLComponents(url: urlPath, resolvingAgainstBaseURL: true) else {
            completion(.failed(Errors.urlComponents))
            return
        }
        urlComponents.queryItems = [URLQueryItem(name: "UserId", value: userId)]

        guard let url = urlComponents.url else {
            completion(.failed(Errors.urlComponents))
            return
        }

        var headers = NetworkRequester.defaultHeader
        headers.insert(UserManager.shared.embyAuthHeader)
        headers.insert(UserManager.shared.embyTokenHeader)

        NetworkRequester().get(at: url, header: headers, completion: completion)
    }

    /// Fetches episodes for a serie
    func fetchEpisodesFor(serieId: String, userId: String, completion: @escaping (NetworkRequesterResponse<QueryResult<PlayableEpisode>>) -> Void) {

        let urlPath = baseUrl.appendingPathComponent("emby/Shows/\(serieId)/Episodes")

        guard var urlComponents = URLComponents(url: urlPath, resolvingAgainstBaseURL: true) else {
            completion(.failed(Errors.urlComponents))
            return
        }
        urlComponents.queryItems = [URLQueryItem(name: "UserId", value: userId)]

        guard let url = urlComponents.url else {
            completion(.failed(Errors.urlComponents))
            return
        }

        var headers = NetworkRequester.defaultHeader
        headers.insert(UserManager.shared.embyAuthHeader)
        headers.insert(UserManager.shared.embyTokenHeader)

        NetworkRequester().get(at: url, header: headers, completion: completion)
    }

    /// Fetches the latest items in a catagory
    func fetchLatestItems(in catagory: MediaFolder, forUserId userId: String, completion: @escaping (NetworkRequesterResponse<[BaseItem]>) -> Void) {

        let urlPath = baseUrl.appendingPathComponent("emby/Users/\(userId)/Items")

        guard var urlComponents = URLComponents(url: urlPath, resolvingAgainstBaseURL: true) else {
            completion(.failed(Errors.urlComponents))
            return
        }
        urlComponents.queryItems = [
            URLQueryItem(name: "ParentId", value: catagory.id),
            URLQueryItem(name: "SortBy", value: "DateCreated"),
            URLQueryItem(name: "SortOrder", value: "Descending"),
            URLQueryItem(name: "Limit", value: "10")
        ]

        guard let url = urlComponents.url else {
            completion(.failed(Errors.urlComponents))
            return
        }

        var headers = NetworkRequester.defaultHeader
        headers.insert(userManager.embyTokenHeader)
        headers.insert(userManager.embyAuthHeader)

        NetworkRequester().get(at: url, header: headers) { (response: NetworkRequesterResponse<QueryResult<BaseItem>>) in
            switch response {
            case .success(let result): completion(.success(result.items))
            case .failed(let error): completion(.failed(error))
            }
        }
    }

    func fetchItemWith(id: String, completion: @escaping (NetworkRequesterResponse<PlayableItem>) -> Void) {

        guard let userId = UserManager.shared.current?.id else { return }
        let url = baseUrl.appendingPathComponent("/emby/Users/\(userId)/Items/\(id)")

        var headers = NetworkRequester.defaultHeader
        headers.insert(UserManager.shared.embyAuthHeader)
        headers.insert(UserManager.shared.embyTokenHeader)

        NetworkRequester().get(at: url, header: headers, completion: completion)
    }

    /// Fetches the top most catagories for a user
    func fetchLibraryTopCatagoriesFor(userId: String, completion: @escaping (NetworkRequesterResponse<QueryResult<MediaFolder>>) -> Void) {
        let url = baseUrl.appendingPathComponent("emby/Users/\(userId)/Views")

        var headers = NetworkRequester.defaultHeader
        headers.insert(userManager.embyAuthHeader)

        NetworkRequester().get(at: url, header: headers, completion: completion)
    }

    /// Fetches all the public users on the server
    func fetchPublicUsers(completion: @escaping (NetworkRequesterResponse<[User]>) -> Void) {
        let url = baseUrl.appendingPathComponent("emby/Users/Public")
        NetworkRequester().get(at: url, header: NetworkRequester.defaultHeader, completion: completion)
    }

    /// Authenticates a user
    func authenticateUserWith(id: String, login: AuthenticateUserByName, completion: @escaping (NetworkRequesterResponse<AuthenticationResult>) -> Void) {

        let authUrl = baseUrl.appendingPathComponent("emby/Users/\(id)/Authenticate")

        var headers = NetworkRequester.defaultHeader
        headers.insert(userManager.embyAuthHeader)

        NetworkRequester().post(at: authUrl, header: headers, body: login, completion: completion)
    }

    func autenticateUser(with login: AuthenticateUserByName, completion: @escaping (NetworkRequesterResponse<AuthenticationResult>) -> Void) {
        let authUrl = baseUrl.appendingPathComponent("emby/Users/AuthenticateByName")

        var headers = NetworkRequester.defaultHeader
        headers.insert(userManager.embyAuthHeader)

        NetworkRequester().post(at: authUrl, header: headers, body: login, completion: completion)
    }

    func logout(_ user: User, completion: @escaping (NetworkRequesterResponse<NoContent>) -> Void) {
        let logutUrl = baseUrl.appendingPathComponent("Sessions/Logout")

        var headers = NetworkRequester.defaultHeader
        headers.insert(userManager.embyAuthHeader)

        NetworkRequester().post(at: logutUrl, header: headers, body: NoContent(), completion: completion)
    }

    func downloadFile(_ item: PlayableItem, supportedContainer: SupportedContainerController) throws {

        guard let video = startPlaybackSession(for: item, in: supportedContainer) else { throw Errors.urlComponents }

        var headers = NetworkRequester.defaultHeader
        headers.insert(userManager.embyAuthHeader)
        headers.insert(userManager.embyTokenHeader)

        var savePath = item.id

        guard let container = item.mediaSources
            .first(where: { supportedContainer.supports(container: $0.container) })?
            .container else { throw Errors.dataDecoding }
        savePath += "." + container
        try ItemDownloadManager.shared.startDownload(for: item, with: video, to: savePath, headers: headers)
    }

    func downloadFile(_ item: SyncItem, supportedContainer: SupportedContainerController) throws -> DownloadManagerDownloadPath {

        guard let container = item.mediaSource?.container else { throw Errors.dataDecoding }
        guard supportedContainer.supports(container: container) else { throw Errors.unsupportedFile(container) }

        let video = Video(url: baseUrl.appendingPathComponent("emby/Sync/JobItems/\(item.id)/File"))
        var headers = NetworkRequester.defaultHeader
        headers.insert(userManager.embyAuthHeader)
        headers.insert(userManager.embyTokenHeader)

        let savePath = "\(item.itemId).\(container)"
        try ItemDownloadManager.shared.startDownload(for: item.playableItem, with: video, to: savePath, headers: headers)
        return video.url.path
}

    func fetchSubtitle(_ subtitleStream: MediaStream, for item: PlayableIteming, completion: @escaping (NetworkRequesterResponse<Subtitles>) -> Void) {

        guard let mediaSource = item.mediaSources.first,
            let streamIndex = subtitleStream.index else { return }
        let urlPath = baseUrl.appendingPathComponent("emby/Videos/\(item.id)/\(mediaSource.id)/Subtitles/\(streamIndex)/Stream.vtt")

        let requester = NetworkRequester()
        _ = requester.getData(from: urlPath) { (response) in
            switch response {
            case .failed(let error): completion(.failed(error))
            case .success(let data):

                do {
                    guard let file = String(data: data, encoding: .utf8) else { throw Errors.dataDecoding }
                    let subtitles = try SubtitleFactory().decodeVTTFormate(file)
                    completion(.success(subtitles))
                } catch let error {
                    completion(.failed(error))
                }
            }
        }
    }

    func subtitleUrl(for subtitleStream: MediaStream, in item: PlayableIteming) -> String {
        guard let mediaSource = item.mediaSources.first,
            let streamIndex = subtitleStream.index else { return "" }
        return baseUrl.appendingPathComponent("emby/Videos/\(item.id)/\(mediaSource.id)/Subtitles/\(streamIndex)/Stream.vtt").absoluteString
    }

    func send(_ jobRequest: SyncManager.JobRequest, completion: @escaping (NetworkRequesterResponse<SyncManager.RequestedJob>) -> Void) {
        let requester = NetworkRequester()

        var headers = NetworkRequester.defaultHeader
        headers.insert(userManager.embyAuthHeader)
        headers.insert(userManager.embyTokenHeader)

        let url = baseUrl.appendingPathComponent("emby/Sync/Jobs")
        requester.post(at: url, header: headers, body: jobRequest, completion: completion)
    }

    func cancelJob(_ job: SyncManager.RequestedJob, completion: @escaping (NetworkRequesterResponse<NoContent>) -> Void) {

        guard let jobId = job.id else { return }
        let requester = NetworkRequester()

        var headers = NetworkRequester.defaultHeader
        headers.insert(userManager.embyAuthHeader)
        headers.insert(userManager.embyTokenHeader)

        let url = baseUrl.appendingPathComponent("emby/Sync/Jobs/\(jobId)")
        requester.delete(at: url, header: headers, completion: completion)
    }

    func fetchJobs(completion: @escaping (NetworkRequesterResponse<QueryResult<SyncManager.RequestedJob>>) -> Void) {
        let requester = NetworkRequester()

        var headers = NetworkRequester.defaultHeader
        headers.insert(userManager.embyAuthHeader)
        headers.insert(userManager.embyTokenHeader)

        let url = baseUrl.appendingPathComponent("emby/Sync/Jobs")
        requester.get(at: url, header: headers, completion: completion)
    }

    func fetchJobItems(completion: @escaping (NetworkRequesterResponse<QueryResult<SyncItem>>) -> Void) {

        let url = baseUrl.appendingPathComponent("emby/Sync/JobItems")

        var headers = NetworkRequester.defaultHeader
        headers.insert(UserManager.shared.embyAuthHeader)
        headers.insert(UserManager.shared.embyTokenHeader)

        NetworkRequester().get(at: url, header: headers, completion: completion)
    }
}
