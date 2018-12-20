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
