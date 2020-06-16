//
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
