//
//  UIImageView+fetchUrl.swift
//  Emby Player
//
//  Created by Mats Mollestad on 29/08/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//

import UIKit

extension UIImageView {
    func fetch(_ url: URL, with cache: NSCache<NSString, UIImage>? = nil, errorHandler: ((Error) -> Void)? = nil) {
        
        if let cache = cache,
            let image = cache.object(forKey: NSString(string: url.absoluteString)) {
            self.image = image
        } else {
            DispatchQueue.global().async { [weak self] in
                do {
                    let data = try Data(contentsOf: url)
                    guard let image = UIImage(data: data) else { return }
                    cache?.setObject(image, forKey: NSString(string: url.absoluteString))
                    DispatchQueue.main.async {
                        self?.image = image
                    }
                } catch let error {
                    errorHandler?(error)
                    print("Error fetching image: \(error)")
                }
            }
        }
    }
}

