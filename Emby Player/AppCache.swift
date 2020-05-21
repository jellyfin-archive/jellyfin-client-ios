/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */
//
//  AppCache.swift
//  Emby Player
//
//  Created by Mats Mollestad on 01/10/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//

import UIKit

/// A class containing all the cahced files
class AppCache {
    static let shared = AppCache()

    private let imageCache = NSCache<NSString, UIImage>()

//    func imageFor(key: String) -> UIImage? {
//        return imageCache.object(forKey: NSString(string: key))
//    }
//    
//    func set(_ image: UIImage, key: String) {
//        imageCache.setObject(image, forKey: NSString(string: key))
//    }
}
