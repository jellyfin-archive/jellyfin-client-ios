/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */
//
//  SyncManager.swift
//  Jellyfin Player
//
//  Created by Mats Mollestad on 01/08/2019.
//  Copyright © 2019 Mats Mollestad. All rights reserved.
//

import Foundation

protocol SyncManagerDelegate: class {
    func jobsDidUpdate(in manager: SyncManager)
}

class SyncManager {

    var fetchTimer: Timer?

    var userManager: UserManager = .shared
    weak var delegate: SyncManagerDelegate? {
        didSet {
            fetchTimer?.invalidate()
            fetchTimer = nil
            if self.delegate != nil {
                scheduledFetch()
            }
        }
    }

    static let shared = SyncManager()

    init() {
        fetchJobs()
    }

    var activeJobs = [Int : ActiveJob]()
    private var jobsReadyToDownload: [Int : ActiveJob] { activeJobs.filter({ $1.job.status == .readyToTransfer }) }
    private var downloadingJobs: [DownloadManagerDownloadPath : ActiveJob] = [:]

    struct ActiveJob : Hashable {

        static func == (lhs: SyncManager.ActiveJob, rhs: SyncManager.ActiveJob) -> Bool {
            lhs.item.id == rhs.item.id
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(item.id)
        }

        let item: SyncItem
        let job: RequestedJob
    }

    struct JobRequest : Codable {
        let targetId: String
        let itemIds: [String]
        let quality: String
        let profile: String = "mobile"
        let name: String
        let userId: String
        let unwatchedOnly: Bool
        let syncNewContent: Bool
    }

    struct RequestedJob : Codable {

        enum Status : String, Codable {
            case queued                 = "Queued"
            case converting             = "Converting"
            case readyToTransfer        = "ReadyToTransfer"
            case transferring           = "Transferring"
            case completed              = "Completed"
            case completedWithError     = "CompletedWithError"
            case failed                 = "Failed"
        }

        let id: Int?
        let targetId: String
        let requestedItemIds: [Int]
        let quality: String
        let profile: String?
        let name: String
        let status: Status
        let progress: Double

        static let failed = RequestedJob(id: 0, targetId: "", requestedItemIds: [], quality: "", profile: "", name: "", status: .failed, progress: 0)

        enum CodingKeys: String, CodingKey {
            case id = "Id"
            case targetId = "TargetId"
            case requestedItemIds = "RequestedItemIds"
            case quality = "Quality"
            case profile = "Profile"
            case name = "Name"
            case status = "Status"
            case progress = "Progress"
        }
    }

    func scheduledFetch() {
        guard fetchTimer == nil else { return }
        fetchTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] (_) in
            self?.fetchJobs()
        }
    }

    func request(_ item: PlayableIteming, in quality: String) {

        guard !activeJobs.contains(where: { $1.item.id == item.id }) else { return }
        guard let userId = userManager.current?.id else { return }

        let request = JobRequest(targetId: userManager.deviceId,
                                 itemIds: [item.id],
                                 quality: quality,
                                 name: item.name,
                                 userId: userId,
                                 unwatchedOnly: false,
                                 syncNewContent: false)

        ServerManager.currentServer?.send(request, completion: { [weak self] (response) in
            switch response {
            case .success(let job): self?.fetchItems(for: [job])
            case .failed(let error): print(error)
            }
        })
    }

    func cancel(_ job: ActiveJob) {
        ServerManager.currentServer?.cancelJob(job.job) { [weak self] (response) in
            switch response {
            case .success(_):
                _ = self?.activeJobs.removeValue(forKey: job.job.id ?? 0)
                if let unownedSelf = self {
                    self?.delegate?.jobsDidUpdate(in: unownedSelf)
                }
            case .failed(let error): print(error)
            }
        }
    }

    @objc
    func fetchJobs() {
        ServerManager.currentServer?.fetchJobs(completion: { [weak self] (response) in
            switch response {
            case .success(let queryJob): self?.update(with: queryJob.items)
            case .failed(let error): print(error)
            }
        })
    }

    private func update(with jobs: [RequestedJob]) {
        for job in jobs {
            if let jobId = job.id,
                let activeJob = activeJobs[jobId] {

                let updatedJob = ActiveJob(item: activeJob.item, job: job)
                activeJobs[jobId] = updatedJob
                delegate?.jobsDidUpdate(in: self)

                if activeJob.item.mediaSource != nil {
                    startDownloading(updatedJob)
                } else if job.status == .readyToTransfer {
                    fetchItems(for: jobs)
                    return
                }
            } else {
                fetchItems(for: jobs)
                return
            }
        }
        if delegate != nil {
            scheduledFetch()
        }
    }

    private func fetchItems(for jobs: [RequestedJob]) {
        ServerManager.currentServer?.fetchJobItems { [weak self] (response) in
            switch response {
            case .success(let query): self?.addJobItems(query.items, and: jobs)
            case .failed(let error):
                print(error)
            }
        }
    }

    private func addJobItems(_ items: [SyncItem], and jobs: [RequestedJob]) {
        activeJobs = jobs.compactMap { (job: RequestedJob) -> ActiveJob? in
            if let item = items.first(where: { item in job.id == item.jobId }) {
                return ActiveJob(item: item, job: job)
            } else {
                return nil
            }
        }.reduce(into: activeJobs) {
            if let id = $1.job.id {
                $0[id] = $1
            }
        } // Creating dict
        delegate?.jobsDidUpdate(in: self)
        if delegate != nil {
            scheduledFetch()
        }
    }

    func startDownloading(_ activeJob: ActiveJob) {
        guard activeJob.job.status == .readyToTransfer, let id = activeJob.job.id else { return }
        guard let server = ServerManager.currentServer else { return }
        do {
            let downloadPath = try server.downloadFile(activeJob.item, supportedContainer: PlayerViewController.supportedContainers)
            downloadingJobs[downloadPath] = activeJobs.removeValue(forKey: id)
            DownloadManager.shared.add(observer: self, forPath: downloadPath)
            delegate?.jobsDidUpdate(in: self)
        } catch {
            print(error)
        }
    }
}

extension SyncManager : DownloadManagerObserverable {

    private func stopSync(with downloadPath: DownloadManagerDownloadPath) {
        guard let activeJob = downloadingJobs[downloadPath] else { return }
        _ = downloadingJobs.removeValue(forKey: downloadPath)
        _ = activeJobs.removeValue(forKey: activeJob.job.id ?? 0)
        delegate?.jobsDidUpdate(in: self)
        ServerManager.currentServer?.cancelJob(activeJob.job, completion: { (_) in })
    }


    func downloadWasCompleted(for downloadPath: DownloadManagerDownloadPath, response: FetcherResponse<DownloadManagerLocalPath>) {
        stopSync(with: downloadPath)
    }

    func downloadWasStopped(for downloadPath: DownloadManagerDownloadPath) {
        stopSync(with: downloadPath)
    }
}
