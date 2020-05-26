/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */
//
//  CatagoryLibraryViewController.swift
//  Jellyfin Player
//
//  Created by Mats Mollestad on 26/08/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//

import UIKit

typealias HorizontalCatagoryLibraryViewControllerDelegate = CatagoryLibraryViewControllerDelegate

class HorizontalCatagoryLatestLibraryViewController: UIViewController, ContentViewControlling {

    let store: LibraryStore<LatestLibraryStoreEmbyCatagoryFetcher>

    var contentViewController: UIViewController { return self }

    lazy var collectionView: UICollectionView = self.setUpCollectionView()

    weak var delegate: HorizontalCatagoryLibraryViewControllerDelegate?

    init(catagory: MediaFolder) {
        let fetcher = LatestLibraryStoreEmbyCatagoryFetcher(catagory: catagory)
        self.store = LibraryStore(fetcher: fetcher)
        super.init(nibName: nil, bundle: nil)
        setUpViewController()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func fetchContent(completion: @escaping (FetcherResponse<Void>) -> Void) {
        store.fetchItems { [weak self] (response) in
            completion(response)
            DispatchQueue.main.async {
                self?.collectionView.isUserInteractionEnabled = self?.store.numberOfItems != 0
            }
        }
    }

    private func setUpViewController() {
        view.backgroundColor = .clear
        view.addSubview(collectionView)
        collectionView.fillSuperView()
    }

    private func setUpCollectionView() -> UICollectionView {

        let minWidth: CGFloat = 150
        let spacing: CGFloat = 10
        let numberOfCells = floor(self.view.frame.width / minWidth)
        let width = self.view.frame.width / numberOfCells
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = spacing
        layout.itemSize = CGSize(width: width, height: 200)

        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.delegate = self
        view.dataSource = self
        view.register(BaseItemCollectionViewCell.self)
        view.backgroundColor = .clear
        view.showsHorizontalScrollIndicator = false
        return view
    }

    private func handleSelection(of item: BaseItem) {

        let contentController: ContentViewControlling!

        if item.type == "Series" {
            let showFetcher = TvShowLigraryStoreEmbyFetcher(serieId: item.id)
            contentController = TvShowLibraryViewController(fetcher: showFetcher)
        } else if item.isFolder == true {
            let mediaFoler = MediaFolder(item: item)
            let fetcher = LibraryStoreEmbyCatagoryFetcher(catagory: mediaFoler)
            contentController = CatagoryLibraryViewController(fetcher: fetcher)
        } else {
            let itemFetcher = SingleItemStoreEmbyFetcher(itemId: item.id)
            contentController = ItemViewController(fetcher: itemFetcher)
        }
        let contentStateController = ContentStateViewController(contentController: contentController, fetchMode: .onAppeare, backgroundColor: .black)
        navigationController?.pushViewController(contentStateController, animated: true)
        contentStateController.title = item.seriesName ?? item.name
    }
}

extension HorizontalCatagoryLatestLibraryViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return store.numberOfItems
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let item = store.itemAt(index: indexPath.row)

        let cell = collectionView.cellForItem(at: indexPath, ofType: BaseItemCollectionViewCell.self)
        cell.titleLabel.text = item.name
        cell.superController = self
        cell.imageUrl = ServerManager.currentServer?.imageUrl(of: .primary, itemId: item.id)
        cell.playedUserData = item.userData
        cell.unplayedCountLabel.text = item.userData.unplayedItemCount == nil ? "" : "\(item.userData.unplayedItemCount ?? 0)"
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = store.itemAt(index: indexPath.row)
        delegate?.itemWasSelected(item)
//        handleSelection(of: item)
    }
}
