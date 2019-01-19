//
//  OngoingDownloadsViewController.swift
//  Emby Player
//
//  Created by Mats Mollestad on 28/09/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//

import UIKit


class OngoingDownloadStore {
    
    var items = [PlayableIteming]()
    var numberOfItems: Int { return items.count }
    
    func fetchContent() {
        items = ItemDownloadManager.shared.activeItems()
    }
    
    func item(at index: Int) -> PlayableIteming {
        return items[index]
    }
    
    func progress(for item: PlayableIteming) -> DownloadProgressable? {
        return ItemDownloadManager.shared.progressFor(itemId: item.id)
    }
}


/// View controller that presents the items that are currently beeing downloaded
class OngoingDownloadsViewController: UIViewController {
    
    var store = OngoingDownloadStore()
    
    lazy var tableView: UITableView = self.createTableView()
    
    
    override func viewDidLoad() {
        setupViewController()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        store.fetchContent()
        tableView.reloadData()
    }
    
    
    private func setupViewController() {
        title = "Active Downloads"
        view.addSubview(tableView)
        tableView.fillSuperView()
    }
    
    private func createTableView() -> UITableView {
        let view = UITableView()
        view.dataSource = self
        view.delegate = self
        view.backgroundColor = .black
        view.rowHeight = UITableView.automaticDimension
        view.separatorColor = UIColor(white: 0.25, alpha: 1)
        view.register(OngoingDownloadTableViewCell.self)
        return view
    }
}


extension OngoingDownloadsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return store.numberOfItems
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = store.item(at: indexPath.row)
        let cell = tableView.cellForItem(at: indexPath, ofType: OngoingDownloadTableViewCell.self)
        cell.item = item
        if let progress = store.progress(for: item) {
            cell.updateContent(progress: progress, written: 0)
        }
        ItemDownloadManager.shared.add(cell, forItemId: item.id)
        return cell
    }
}
