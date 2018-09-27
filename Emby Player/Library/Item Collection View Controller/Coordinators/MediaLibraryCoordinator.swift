//
//  MediaLibraryCoordinator.swift
//  Emby Player
//
//  Created by Mats Mollestad on 13/09/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//

import UIKit


class MediaLibraryCoordinator: Coordinating, CatagoryLibraryViewControllerDelegate {
    
    let presenter: UINavigationController
    
    
    var mediaFolder: MediaFolder?
    
    var mediaController: CatagoryLibraryViewController<LibraryStoreEmbyCatagoryFetcher>?
    
    var coordinator: Coordinating?
    
    init(presenter: UINavigationController, mediaFolder: MediaFolder? = nil) {
        self.presenter = presenter
        self.mediaFolder = mediaFolder
    }
    
    func start() {
        guard let mediaFolder = mediaFolder else { return }
        let fetcher = LibraryStoreEmbyCatagoryFetcher(catagory: mediaFolder)
        mediaController = CatagoryLibraryViewController(fetcher: fetcher)
        mediaController?.delegate = self
        mediaController?.title = mediaFolder.name
        let contentViewController = ContentStateViewController(contentController: mediaController!, fetchMode: .onAppeare, backgroundColor: .black)
        presenter.pushViewController(contentViewController, animated: true)
    }
    
    
    func itemWasSelected(_ item: BaseItem) {
        if item.type == "Series" {
            coordinator = TvShowCoordinator(presenter: presenter, item: item)
        } else if item.isFolder == true {
            let mediaFoler = MediaFolder(item: item)
            coordinator = MediaLibraryCoordinator(presenter: presenter, mediaFolder: mediaFoler)
        } else {
            coordinator = EmbyItemCoordiantor(presenter: presenter, itemId: item.id) 
        }
        
        coordinator?.start()
    }
}
