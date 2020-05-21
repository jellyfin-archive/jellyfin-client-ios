/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */
//
//  UIImageView+fetchUrl.swift
//  Emby Player
//
//  Created by Mats Mollestad on 29/08/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//

import UIKit

extension UIImageView {
    func fetch(_ url: URL, with cache: NSCache<NSString, UIImage>? = nil, errorHandler: ((Error) -> Void)? = nil) -> URLSessionTask? {
        image = nil
        if let cache = cache,
            let image = cache.object(forKey: NSString(string: url.absoluteString)) {
            self.image = image
            return nil
        } else {
            return NetworkRequester().getData(from: url) { [weak self] (response) in
                switch response {
                case .success(let data):
                    guard let image = UIImage(data: data) else { return }
                    cache?.setObject(image, forKey: NSString(string: url.absoluteString))
                    DispatchQueue.main.async {
                        self?.image = image
                    }
                case .failed(let error):
                    errorHandler?(error)
                }
            }
        }
    }
}
