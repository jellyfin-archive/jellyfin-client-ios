//
//  VideoPlayerCoordinator.swift
//  Emby Player
//
//  Created by Mats Mollestad on 13/09/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//

import UIKit


class VideoPlayerCoordinator: Coordinating, PlayerViewControllerDelegate {
    
    var item: PlayableItem?
    
    let presenter: UIViewController
    
    init(presenter: UIViewController) {
        self.presenter = presenter
    }
    
    func start() {
        
        DeviceRotateManager.shared.allowedOrientations = .landscape
        
        guard let item = item,
            let server = ServerManager.currentServer else { return }
        
        let playerController = PlayerViewController()
        playerController.delegate = self
        
        playerController.playableItem = item
        playerController.video = item.playableVideo(in: playerController, from: server)
        
        presenter.present(playerController, animated: true) { [weak playerController] in
            playerController?.playVideo()
        }
    }
    
    
    func playerWillDisappear(_ player: PlayerViewController) {
        DeviceRotateManager.shared.allowedOrientations = .allButUpsideDown
        guard let item = item,
            let userId = UserManager.shared.current?.id else { return }
        
        let fraction = player.currentTime.seconds / player.duration.seconds
        if fraction > 0.93 {
            ServerManager.currentServer?.markItemAsWatched(item, userId: userId)
        }
    }
}
