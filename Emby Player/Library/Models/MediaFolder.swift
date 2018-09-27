//
//  MediaFolder.swift
//  Emby Player
//
//  Created by Mats Mollestad on 31/08/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//

import Foundation


struct MediaFolder: Codable {
    
    let name: String
    let id: String
    let path: String?
    let isFolder: Bool
    let type: String
    
    enum CodingKeys: String, CodingKey {
        case name           = "Name"
        case id             = "Id"
        case path           = "Path"
        case isFolder       = "IsFolder"
        case type           = "Type"
    }
    
    init(item: BaseItem) {
        name = item.name
        id = item.id
        path = item.path
        isFolder = item.isFolder ?? false
        type = item.type ?? "Unknown"
    }
}
