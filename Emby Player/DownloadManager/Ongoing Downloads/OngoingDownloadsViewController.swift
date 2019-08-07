//
//  OngoingDownloadsViewController.swift
//  Emby Player
//
//  Created by Mats Mollestad on 28/09/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//

import UIKit

class OngoingDownloadStore {

    weak var delegate: SyncManagerDelegate? {
        get { syncManager.delegate }
        set { syncManager.delegate = newValue }
    }

    var downloadingItems = [PlayableIteming]()
    var numberOfDownloadingItems: Int { return downloadingItems.count }

    var syncingJobs = [SyncManager.ActiveJob]()
    var numberOfSyncingJobs: Int { syncingJobs.count }

    var syncManager = SyncManager.shared

    func fetchContent() {
        downloadingItems = ItemDownloadManager.shared.activeItems()
        syncingJobs = Array(syncManager.activeJobs.values)
            .filter({ $0.job.targetId == UserManager.shared.deviceId })
            .filter({ $0.job.status != .transferring })
            .sorted(by: { $0.item.id < $1.item.id })
    }

    func downloadingItem(at index: Int) -> PlayableIteming? {
        guard downloadingItems.count > index else { return nil }
        return downloadingItems[index]
    }

    func downloadingProgress(for item: PlayableIteming) -> DownloadProgressable? {
        return ItemDownloadManager.shared.progressFor(itemId: item.id)
    }

    func job(at index: Int) -> SyncManager.ActiveJob? {
        guard syncingJobs.count > index else { return nil }
        return syncingJobs[index]
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
        store.delegate = self
        store.fetchContent()
        tableView.reloadData()
        store.syncManager.scheduledFetch()
    }

    override func viewWillDisappear(_ animated: Bool) {
        store.delegate = nil
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
        view.register(SyncJobTableViewCell.self)
        return view
    }
}

extension OngoingDownloadsViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return store.numberOfDownloadingItems
        } else {
            return store.numberOfSyncingJobs
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let text = section == 0 ? "Downloading - \(store.numberOfDownloadingItems)" : "Converting - \(store.numberOfSyncingJobs)"
        let label = ViewBuilder.textLabel(font: .title2, text: text)
        let stackView = ViewBuilder.stackView(arrangedSubviews: [label],
                                              layoutMargins: UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16))
        let section = UIView()
        section.backgroundColor = UIColor(white: 0.05, alpha: 1)
        section.addSubview(stackView)
        stackView.fillSuperView()
        return section
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.cellForItem(at: indexPath, ofType: OngoingDownloadTableViewCell.self)
            cell.item = store.downloadingItem(at: indexPath.row)
            if let item = cell.item,
                let progress = store.downloadingProgress(for: item) {
                cell.updateContent(progress: progress, written: 0)
                ItemDownloadManager.shared.add(cell, forItemId: item.id)
            }
            return cell
        } else {
            let cell = tableView.cellForItem(at: indexPath, ofType: SyncJobTableViewCell.self)
            cell.job = store.job(at: indexPath.row)
//            if let progress = store.downloadingProgress(for: item) {
//                cell.updateContent(progress: progress, written: 0)
//            }
//            ItemDownloadManager.shared.add(cell, forItemId: item.id)
            return cell
        }
    }


//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        guard indexPath.section == 1 else { return }
//        let job = store.job(at: indexPath.row)
//        store.syncManager.startDownloading(job)
//    }
}

extension OngoingDownloadsViewController : SyncManagerDelegate {
    func jobsDidUpdate(in manager: SyncManager) {
        DispatchQueue.main.async { [weak self] in
            self?.store.fetchContent()
            self?.tableView.reloadData()
        }
    }
}
