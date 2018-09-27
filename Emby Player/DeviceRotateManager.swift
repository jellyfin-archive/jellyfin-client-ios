//
//  DeviceRotateManager.swift
//  Emby Player
//
//  Created by Mats Mollestad on 06/09/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//

import UIKit

struct DeviceRotateManager {
    static var shared = DeviceRotateManager()
    var allowedOrientations: UIInterfaceOrientationMask = .allButUpsideDown
}
