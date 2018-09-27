//
//  HLSDecoder.swift
//  Emby Player
//
//  Created by Mats Mollestad on 11/09/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//

import Foundation

typealias HLSHeader = [String : String]

class HLSFile: Hashable {
    let header: HLSHeader
    let items: [HLSItem]
    
    init(header: HLSHeader, items: [HLSItem]) {
        self.header = header
        self.items = items
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(header)
        hasher.combine(items)
    }
    
    static func == (lhs: HLSFile, rhs: HLSFile) -> Bool {
        return lhs.header == rhs.header && lhs.items == rhs.items
    }
    
    func writeToFile(at url: URL) throws {
        var file = "#EXTM3U\n"
        file += header.reduce("") { $0 + "EXT-X-" + $1.key + ":" + $1.value + "\n" }
        file += items.reduce("") { $0 + "EXTINF:\($1.lenght), nodesc\n" + $1.urlPath + "\n" }
        file += "EXT-X-END\n"
        let data = file.data(using: .utf8)
        try data?.write(to: url)
    }
}

struct HLSItem: Hashable {
    let urlPath: String
    let urlQueryItems: [URLQueryItem]
    let lenght: TimeInterval
}


class HLSDecoder {
    
    enum Errors: Error {
        case unableToDecodeItemLine
        case uncbleToDecodeData
    }
    
    func decode(data: Data, encoding: String.Encoding) throws -> HLSFile {
        guard let file = String(data: data, encoding: encoding) else { throw Errors.uncbleToDecodeData }
        return try decode(file: file)
    }
    
    func decode(file: String) throws -> HLSFile {
        var header = [String : String]()
        var items = [HLSItem]()
        let lines = file.components(separatedBy: "\n#")
        
        for line in lines {
            if line.hasPrefix("EXTINF:") { // HLS Item
                let sublines = line.components(separatedBy: "\n")
                let charSet = CharacterSet(charactersIn: ":,")
                let itemInfo = sublines[0].components(separatedBy: charSet)
                guard let lenght = TimeInterval(itemInfo[1]) else { throw Errors.unableToDecodeItemLine }
                let pathComponents = sublines[1].components(separatedBy: "?")
                let urlPath = pathComponents[0]
                var urlQueryItems = [URLQueryItem]()
                if pathComponents.count == 2 {
                    urlQueryItems = self.urlQueryItems(from: pathComponents[1])
                }
                let item = HLSItem(urlPath: urlPath, urlQueryItems: urlQueryItems, lenght: lenght)
                items.append(item)
            } else if line.hasPrefix("EXT-X-") {
                let headerInfo = line.components(separatedBy: ":")
                if headerInfo.count > 1 {
                    header[headerInfo[0]] = headerInfo[1]
                }
            }
        }
        
        return HLSFile(header: header, items: items)
    }
    
    
    func urlQueryItems(from path: String) -> [URLQueryItem] {
        var queryItems = [URLQueryItem]()
        let querys = path.components(separatedBy: "&")
        
        for query in querys {
            let components = query.components(separatedBy: "=")
            if components.count == 2 {
                queryItems.append(URLQueryItem(name: components[0], value: components[1]))
            }
        }
        return queryItems
    }
}
