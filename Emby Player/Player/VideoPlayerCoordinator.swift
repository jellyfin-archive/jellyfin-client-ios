//
//  VideoPlayerCoordinator.swift
//  Emby Player
//
//  Created by Mats Mollestad on 13/09/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//

import UIKit


class VideoPlayerCoordinator: Coordinating, PlayerViewControllerDelegate {
    
    var info: (item: PlayableIteming, video: Video)?
    
    let presenter: UIViewController
    lazy var playerController = PlayerViewController()
    
    init(presenter: UIViewController) {
        self.presenter = presenter
    }
    
    func start() {
        
        DeviceRotateManager.shared.allowedOrientations = .landscape
        
        guard let info = info else { return }
        
        playerController.delegate = self
        
        playerController.playableItem = info.item
        playerController.video = info.video
        
        presenter.present(playerController, animated: true) { [weak playerController] in
            playerController?.playVideo()
        }
    }
    
    
    func playerWillDisappear(_ player: PlayerViewController) {
        DeviceRotateManager.shared.allowedOrientations = .allButUpsideDown
        guard let item = info?.item,
            let userId = UserManager.shared.current?.id else { return }
        
        let fraction = player.currentTime.seconds / player.duration.seconds
        if fraction > 0.93 {
            ServerManager.currentServer?.markItemAsWatched(item, userId: userId)
        }
    }
}
