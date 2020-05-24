/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */
//
//  FetcherResponse.swift
//  Jellyfin Player
//
//  Created by Mats Mollestad on 26/09/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//

import Foundation

enum FetcherResponse<T> {
    case success(T)
    case failed(Error)

    init(response: NetworkRequesterResponse<T>) {
        switch response {
        case .success(let value): self = FetcherResponse<T>.success(value)
        case .failed(let error): self = .failed(error)
        }
    }
}
