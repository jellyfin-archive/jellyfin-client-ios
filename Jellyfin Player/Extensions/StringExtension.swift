//
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */
//  StringExtension.swift
//  Jellyfin Player
//
//  Created by Ciarán Mulholland on 16/06/2020.
//  Copyright © 2020 Mats Mollestad. All rights reserved.
//

import Foundation

extension String {
    var isNotBlankOrEmpty: Bool {
        return !self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
