//
//  BaseItem.swift
//  Emby Player
//
//  Created by Mats Mollestad on 26/08/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//

import UIKit

struct QueryResult<T: Codable>: Codable {
    let items: [T]
    let totalRecordCount: Int
    
    enum CodingKeys: String, CodingKey {
        case items              = "Items"
        case totalRecordCount   = "TotalRecordCount"
    }
}


struct MediaSource: Codable {
    let id: String
    let container: String
    let name: String
    let path: String
    let liveStreamId: String?
    let supportsDirectPlay: Bool
    let supportsDirectStream: Bool
    let supportsTranscoding: Bool
    let tag: String?
    
    enum CodingKeys: String, CodingKey {
        case id                     = "Id"
        case container              = "Container"
        case name                   = "Name"
        case path                   = "Path"
        case liveStreamId           = "LiveStreamId"
        case supportsDirectPlay     = "SupportsDirectPlay"
        case supportsDirectStream   = "SupportsDirectStream"
        case supportsTranscoding    = "SupportsTranscoding"
        case tag                    = "Etag"
    }
}


enum ImageType: String {
    case primary    = "Primary"
    case art        = "Art"
    case backdrop   = "Backdrop"
    case banner     = "Banner"
    case logo       = "Logo"
    case thumb      = "Thumb"
    case disc       = "Disc"
    case box        = "Box"
    case screenshot = "Screenshot"
    case menu       = "Menu"
    case chapter    = "Chapter"
}


protocol PlayableIteming: Codable {
    
    var name:               String          { get }
    var id:                 String          { get }
    var sourceType:         String?         { get }
    var hasSubtitle:        Bool?           { get }
    var path:               String?         { get }
    var overview:           String?         { get }
    var seasonTitleText:    String?         { get }
    var mediaSource:        [MediaSource]   { get }
    var mediaStreams:       [MediaStream]   { get }
    var type:               String          { get }
    var userData:           UserData?       { get }
    var runTime:            Int             { get }
    
    var diskUrlPath:        String?         { get }
    
//    func imageUrl(with type: ImageType) -> URL?
    func playableVideo(in player: PlayerViewControllable, from server: EmbyAPI) -> Video?
}

extension PlayableIteming {
    func imageUrl(with type: ImageType) -> URL? {
        return URL(string: "http://server753.seedhost.eu:8096/emby/Items/\(id)/Images/\(type.rawValue)")
    }
    
    func playableVideo(in player: PlayerViewControllable, from server: EmbyAPI) -> Video? {
        
        guard let mediaSource = mediaSource.first else { return nil }
        guard let videoStream = mediaStreams.filter({ $0.type == "Video" }).first else { return nil }
        guard let audioStream = mediaStreams.filter({ $0.type == "Audio" }).first else { return nil }
        
        
        let baseUrl = server.baseUrl
        
        var urlPathString = "emby/Videos/\(id)/"
        
        if player.supports(format: mediaSource.container),
            videoStream.codec != "mpeg4" {  // AVPlayerLayer do not play mpeg4
            
            urlPathString += "stream.\(mediaSource.container)"
            let urlPath = baseUrl.appendingPathComponent(urlPathString)
            guard var urlComponents = URLComponents(url: urlPath, resolvingAgainstBaseURL: true) else { return nil }
            urlComponents.queryItems = [
                URLQueryItem(name: "Static", value: "true"),
                URLQueryItem(name: "mediaSourceId", value: mediaSource.id),
                URLQueryItem(name: "deviceId", value: UIDevice.current.identifierForVendor?.uuidString ?? "xxxx"),
                URLQueryItem(name: "AudioCodec", value: audioStream.codec),
                URLQueryItem(name: "VideoCodec", value: videoStream.codec),
            ]
            guard let url = urlComponents.url else { return nil }
            return Video(url: url)
        } else {
            urlPathString += "main.m3u8"
            let urlPath = baseUrl.appendingPathComponent(urlPathString)
            guard var urlComponents = URLComponents(url: urlPath, resolvingAgainstBaseURL: true) else { return nil }
            urlComponents.queryItems = [
                URLQueryItem(name: "MediaSourceId", value: mediaSource.id),
                URLQueryItem(name: "DeviceId", value: UIDevice.current.identifierForVendor?.uuidString ?? "xxxx"),
                URLQueryItem(name: "AudioCodec", value: "mp3"),
                URLQueryItem(name: "VideoCodec", value: "h264"),
            ]
            guard let url = urlComponents.url else { return nil }
            return Video(url: url)

        }
        
    }
}

struct PlayableMovie: PlayableIteming {
    let userData: UserData?
    let id: String
    var hasSubtitle: Bool?
    var aspectRatio: String
    var width: Int
    var height: Int
    var mediaSource: [MediaSource]
    var mediaStreams: [MediaStream]
    var type: String
    let name: String
    let originalTitle: String?
    let sourceType: String?
    let path: String?
    let overview: String?
    let isHD: Bool?
    let seasonTitleText: String? = nil
    var diskUrlPath: String?
    let runTime: Int
    
    enum CodingKeys: String, CodingKey {
        case name           = "Name"
        case originalTitle  = "OriginalTitle"
        case id             = "Id"
        case sourceType     = "SourceType"
        case hasSubtitle    = "HasSubtitles"
        case path           = "Path"
        case overview       = "Overview"
        case aspectRatio    = "AspectRatio"
        case isHD           = "IsHD"
        case width          = "Width"
        case height         = "Height"
        case mediaSource    = "MediaSources"
        case type           = "Type"
        case mediaStreams   = "MediaStreams"
        case userData       = "UserData"
        case diskUrlPath    = "DiskUrlPath"
        case runTime        = "RunTimeTicks"
    }
}

struct PlayableEpisode: Codable {
    let name: String
    let id: String
    let sourceType: String?
    let hasSubtitle: Bool?
    let path: String?
    let overview: String?
    var seasonTitleText: String? {
        guard let seriesName = seriesName, let seasonName = seasonName else { return nil }
        return seriesName + ", " + seasonName
    }
    var episodeText: String? {
        guard let indexNumber = indexNumber else { return "" }
        return "Episode \(indexNumber)" + (seasonName != nil ? ", \(seasonName!)" : "")
    }
    let type: String
    
    let indexNumber: Int?
    let seriesId: String?
    let seriesName: String?
    let seasonName: String?
    
    let userData: UserData
    
    enum CodingKeys: String, CodingKey {
        case name           = "Name"
        case id             = "Id"
        case sourceType     = "SourceType"
        case hasSubtitle    = "HasSubtitles"
        case path           = "Path"
        case overview       = "Overview"
        case seriesId       = "SeriesId"
        case seriesName     = "SeriesName"
        case seasonName     = "SeasonName"
        case indexNumber    = "IndexNumber"
        case type           = "Type"
        case userData       = "UserData"
    }
    
//    func imageUrl(with type: ImageType) -> URL? {
//        return URL(string: "http://server753.seedhost.eu:8096/emby/Items/\(id)/Images/\(type.rawValue)")
//    }
}


struct PlayableItem: PlayableIteming, Hashable {
    
    static func == (lhs: PlayableItem, rhs: PlayableItem) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    let name: String
    let id: String
    let sourceType: String?
    let hasSubtitle: Bool?
    let path: String?
    let overview: String?
    let seasonName: String?
    let seriesName: String?
    let indexNumber: Int?
    var seasonTitleText: String? { return seasonName }
    let mediaSource: [MediaSource]
    let mediaStreams: [MediaStream]
    let type: String
    let userData: UserData?
    let runTime: Int
    
    /// Used to store the url for an item that is saved offline
    var diskUrlPath: String?
    
    enum CodingKeys: String, CodingKey {
        case name           = "Name"
        case id             = "Id"
        case sourceType     = "SourceType"
        case hasSubtitle    = "HasSubtitles"
        case path           = "Path"
        case overview       = "Overview"
        case seriesName     = "SeriesName"
        case seasonName     = "SeasonName"
        case indexNumber    = "IndexNumber"
        case mediaSource    = "MediaSources"
        case mediaStreams   = "MediaStreams"
        case type           = "Type"
        case userData       = "UserData"
        case diskUrlPath    = "DiskUrlPath"
        case runTime        = "RunTimeTicks"
    }
}


struct BaseItem: Codable {
    let name: String
    let originalTitle: String?
    let id: String
    let sourceType: String?
    let hasSubtitle: Bool?
    let path: String?
    let overview: String?
    let aspectRatio: String?
    let isHD: Bool?
    let seriesId: String?
    let seriesName: String?
    let seasonName: String?
    let width: Int?
    let height: Int?
    let mediaSource: [MediaSource]?
    let mediaStreams: [MediaStream]?
    let indexNumber: Int?
    let isFolder: Bool?
    let type: String?
    
    let userData: UserData
    
    
    init(name: String, originalTitle: String?, id: String, sourceType: String?, hasSubtitle: Bool?, path: String?, overview: String?, aspectRatio: String?, isHD: Bool?, seriesId: String?, seriesName: String?, seasonName: String?, width: Int?, height: Int?, mediaSource: [MediaSource]?, mediaStreams: [MediaStream]?, indexNumber: Int?, isFolder: Bool?, type: String?, userData: UserData) {
        self.name = name
        self.originalTitle = originalTitle
        self.id = id
        self.sourceType = sourceType
        self.hasSubtitle = hasSubtitle
        self.path = path
        self.overview = overview
        self.aspectRatio = aspectRatio
        self.isHD = isHD
        self.seriesId = seriesId
        self.seriesName = seriesName
        self.seasonName = seasonName
        self.width = width
        self.height = height
        self.mediaStreams = mediaStreams
        self.mediaSource = mediaSource
        self.indexNumber = indexNumber
        self.isFolder = isFolder
        self.type = type
        self.userData = userData
    }
    
    init(item: PlayableItem) {
        let userData = item.userData ?? UserData(key: "Key",
                                                 unplayedItemCount: nil,
                                                 playbackPositionTicks: 0,
                                                 playCount: 0,
                                                 isFavorite: false,
                                                 played: false)
        self.init(name: item.name,
                  originalTitle: nil,
                  id: item.id,
                  sourceType: item.sourceType,
                  hasSubtitle: item.hasSubtitle,
                  path: item.path,
                  overview: item.overview,
                  aspectRatio: nil,
                  isHD: nil,
                  seriesId: nil,
                  seriesName: item.seriesName,
                  seasonName: item.seasonName,
                  width: nil,
                  height: nil,
                  mediaSource: item.mediaSource,
                  mediaStreams: item.mediaStreams,
                  indexNumber: item.indexNumber,
                  isFolder: false,
                  type: item.type,
                  userData: userData)
    }
    
    enum CodingKeys: String, CodingKey {
        case name           = "Name"
        case originalTitle  = "OriginalTitle"
        case id             = "Id"
        case sourceType     = "SourceType"
        case hasSubtitle    = "HasSubtitle"
        case path           = "Path"
        case overview       = "Overview"
        case aspectRatio    = "AspectRatio"
        case isHD           = "IsHD"
        case seriesId       = "SeriesId"
        case seriesName     = "SeriesName"
        case seasonName     = "SeasonName"
        case width          = "Width"
        case height         = "Height"
        case mediaSource    = "MediaSources"
        case indexNumber    = "IndexNumber"
        case isFolder       = "IsFolder"
        case type           = "Type"
        case mediaStreams   = "MediaStreams"
        case userData       = "UserData"
    }
    
    func session(positionTicks: Int? = nil) -> PlaybackStart {
        return PlaybackStart(queueableMediaTypes: [.video],
                              canSeek: true,
                              items: [],
                              itemId: id,
                              mediaSourceId: mediaSource?.first?.id ?? "",
                              audioStreamIndex: nil,
                              subtitleStreamIndex: nil,
                              isPaused: false,
                              isMuted: false,
                              positionTicks: positionTicks ?? userData.playbackPositionTicks,
                              volumeLevel: nil,
                              playMethode: .directPlay,
                              liveStreamId: "LiveStreamId",
                              playSessionId: "PlaySessionId")
    }
    
//    func imageUrl(with type: ImageType) -> URL? {
//        return URL(string: "http://server753.seedhost.eu:8096/emby/Items/\(id)/Images/\(type.rawValue)")
//    }
    
    func playableVideo(in player: PlayerViewControllable, from server: EmbyAPI) -> Video? {
        guard let mediaSource = mediaSource?.first else { return nil }
        let baseUrl = server.baseUrl
        
        if mediaSource.supportsDirectStream,
            player.supports(format: mediaSource.container) {
            
            let urlPath = baseUrl.appendingPathComponent("emby/Videos/\(id)/stream.\(mediaSource.container)")
            guard var urlComponents = URLComponents(url: urlPath, resolvingAgainstBaseURL: true) else { return nil }
            urlComponents.queryItems = [
                URLQueryItem(name: "Static", value: "true"),
                URLQueryItem(name: "mediaSourceId", value: mediaSource.id),
                URLQueryItem(name: "deviceId", value: "xxxx"),
            ]
            guard let url = urlComponents.url else { return nil }
            return Video(url: url)
        } else if mediaSource.supportsDirectPlay {
            
            let urlPath = baseUrl.appendingPathComponent("emby/Videos/\(id)/main.m3u8")
            guard var urlComponents = URLComponents(url: urlPath, resolvingAgainstBaseURL: true) else { return nil }
            urlComponents.queryItems = [
                //                URLQueryItem(name: "PlaySessionId", value: ""),
                URLQueryItem(name: "MediaSourceId", value: mediaSource.id),
                URLQueryItem(name: "DeviceId", value: "xxxx"),
                
            ]
            guard let url = urlComponents.url else { return nil }
            return Video(url: url)
            
        } else {
            print("Item du not support Direct Stream")
            return nil
        }
    }
}
