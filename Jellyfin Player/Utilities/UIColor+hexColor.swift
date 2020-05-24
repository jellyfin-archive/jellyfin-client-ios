/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */
//
//  UIColor+hexColor.swift
//  Jellyfin Player
//
//  Created by Mats Mollestad on 09/09/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//

import UIKit

extension UIColor {
    convenience init(hexString: String) {
        let hexString = hexString.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        let scanner   = Scanner(string: hexString)

        if hexString.hasPrefix("#") {
            scanner.scanLocation = 1
        }

        var color: UInt32 = 0
        scanner.scanHexInt32(&color)

        let mask = 0x000000FF
        let redHex = Int(color >> 16) & mask
        let greenHex = Int(color >> 8) & mask
        let blueHex = Int(color) & mask

        let red   = CGFloat(redHex) / 255.0
        let green = CGFloat(greenHex) / 255.0
        let blue  = CGFloat(blueHex) / 255.0

        self.init(red: red, green: green, blue: blue, alpha: 1)
    }

    open func hexCode() -> String {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        let rgb: Int = (Int)(red*255)<<16 | (Int)(green*255)<<8 | (Int)(blue*255)<<0

        return String(format: "#%06x", rgb)
    }
}
