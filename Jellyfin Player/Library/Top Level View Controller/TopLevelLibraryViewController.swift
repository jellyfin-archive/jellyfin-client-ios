/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */
//
//  LibraryViewController.swift
//  Jellyfin Player
//
//  Created by Mats Mollestad on 26/08/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//

import UIKit

protocol TopLevelLibraryViewControllerDelegate: HorizontalCatagoryLibraryViewControllerDelegate {
    func folderWasSelected(_ folder: MediaFolder)
    func userDidLogout()
}

class TopLevelLibraryViewController<Fetcher: LibraryStoreFetchable>: UIViewController, ContentViewControlling, UITableViewDelegate, UITableViewDataSource where Fetcher.LibraryItem == MediaFolder {

    let topCatagoryStore: LibraryStore<Fetcher>

    lazy var tableView: UITableView = self.setUpTableView()

    weak var delegate: TopLevelLibraryViewControllerDelegate? {
        didSet { tableView.reloadData() }
    }

    init(fetcher: Fetcher) {
        topCatagoryStore = LibraryStore<Fetcher>(fetcher: fetcher)
        super.init(nibName: nil, bundle: nil)
        setUpViewController()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init?(coder aDecoder: NSCoder) Not implemented")
    }

    private func setUpViewController() {
        title = "Library"
        tabBarItem.image = UIImage(named: "folder-cloud")
        view.backgroundColor = .black
        view.addSubview(tableView)

        tableView.fillSuperView()
    }

    func fetchContent(completion: @escaping (FetcherResponse<Void>) -> Void) {
        topCatagoryStore.fetchItems(completion: completion)
    }

    override func viewWillAppear(_ animated: Bool) {
        if #available(iOS 11, *) {
            navigationItem.largeTitleDisplayMode = .always
            navigationController?.navigationBar.prefersLargeTitles = true
        }
    }

    private func setUpTableView() -> UITableView {
        let tableView = UITableView()
        tableView.backgroundColor = .clear
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 300
        tableView.register(MediaFolderTableViewCell.self)
        return tableView
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return topCatagoryStore.numberOfItems
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = topCatagoryStore.itemAt(index: indexPath.row)

        let cell = tableView.cellForItem(at: indexPath, ofType: MediaFolderTableViewCell.self)
        cell.superViewController = self
        cell.catagory = item
        cell.backgroundColor = .clear
        cell.delegate = delegate
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let folder = topCatagoryStore.itemAt(index: indexPath.row)
        delegate?.folderWasSelected(folder)
    }
}
