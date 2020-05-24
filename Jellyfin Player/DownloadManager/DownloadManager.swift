/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */
//
//  DownloadManager.swift
//  Jellyfin Player
//
//  Created by Mats Mollestad on 07/09/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//

import Foundation

protocol DownloadManagerObserverable {
    var id: String { get }
    func downloadDidUpdate(_ progress: DownloadRequest, downloaded: Int)
    func downloadWasCompleted(for downloadPath: DownloadManagerDownloadPath, response: FetcherResponse<DownloadManagerLocalPath>)
    func downloadWasStopped(for downloadPath: DownloadManagerDownloadPath)
}

extension DownloadManagerObserverable {
    var id: String { return String(describing: type(of: self)) }
    func downloadDidUpdate(_ progress: DownloadRequest, downloaded: Int) {}
    func downloadWasCompleted(for downloadPath: DownloadManagerDownloadPath, response: FetcherResponse<DownloadManagerLocalPath>) {}
    func downloadWasStopped(for downloadPath: DownloadManagerDownloadPath) {}
}

protocol DownloadProgressable {
    var expectedContentLength: Int { get }
    func progress(with writtenBytes: Int) -> Double
}

typealias DownloadManagerLocalPath = String
typealias DownloadManagerDownloadPath = String

class DownloadRequest: DownloadProgressable, Codable {

    /// The url used to download the item
    /// Used to id which DownloadRequest to update on URLSessionDelegate
    let downloadPath: String
    var expectedContentLength: Int
    let saveUrlPath: String
    var saveUrl: URL? {
        do {
            let directory = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            return directory.appendingPathComponent(saveUrlPath)
        } catch {
            print("Unable to get directory: ", error)
        }
        return nil
    }

    func progress(with writtenBytes: Int) -> Double {
        return Double(writtenBytes) / Double(expectedContentLength)
    }

    init(downloadPath: String, expectedContentLength: Int, saveUrlPath: String) {
        self.downloadPath = downloadPath
        self.expectedContentLength = expectedContentLength
        self.saveUrlPath = saveUrlPath
    }
}

struct DownloadInformation<T: Codable & Hashable>: Codable, Hashable {
    let id: String
    let lastPathConponent: String
    let item: T
}

/// A class used to coordinate downloades of differnet types of files from an url
class DownloadManager: NSObject, URLSessionDownloadDelegate {

    private struct Strings {
        static let errorNotificatonKey = "error"
        static let progressNotificationKey = "progress"
        static let activeDownloads = "activeDownloads"
    }

    enum Errors: Error {
        case networkError
        case unknownError
        case missingSaveUrl
    }

    static let shared = DownloadManager()

    var fileManager: FileManager = .default
    var activeDownloads = [String: DownloadRequest]()
    private var tasks = [DownloadManagerDownloadPath: URLSessionDownloadTask]()
    private var observers = [DownloadManagerDownloadPath: [DownloadManagerObserverable]]()
    private let sessionConfig = URLSessionConfiguration.background(withIdentifier: String(describing: DownloadManager.self))
    private lazy var session = URLSession(configuration: sessionConfig, delegate: self, delegateQueue: nil)

    override init() {
        super.init()
        loadActiveDownloads()
        session.getAllTasks { tasks in
            tasks.group(by: \.originalRequest?.url).compactMap({ $0.value.first }).forEach {
                $0.resume()
            }
        }
    }

    /// Starts downloading a file from an url
    ///
    /// - parameter downloadUrl: The url to download from
    /// - parameter saveUrlPath: The path to save the file to
    /// - parameter headers: The headers needed to download the file
    func startDownload(from downloadUrl: URL, to saveUrlPath: String, with headers: NetworkRequesterHeader) {

        let progress = DownloadRequest(downloadPath: downloadUrl.path, expectedContentLength: 0, saveUrlPath: saveUrlPath)
        guard activeDownloads[progress.downloadPath] == nil else { return }
        activeDownloads[progress.downloadPath] = progress
        saveActiveDownloads()

        let body: String? = nil
        let requester = NetworkRequester()
        requester.session = session
        tasks[progress.downloadPath] = requester.downloadFile(from: downloadUrl, header: headers, body: body)
    }

    func stateFor(urlPath: DownloadManagerDownloadPath) -> URLSessionTask.State? {
        return tasks[urlPath]?.state
    }

    func cancleTask(withUrlPath path: DownloadManagerDownloadPath) {
        tasks[path]?.cancel()
        tasks[path] = nil
        activeDownloads[path] = nil
        if let observers = self.observers[path] {
            observers.forEach { $0.downloadWasStopped(for: path) }
        }
        observers[path] = nil
    }

    func add(observer: DownloadManagerObserverable, forPath path: DownloadManagerDownloadPath) {
        observers[path] = (observers[path] ?? []) + [observer]
    }

    func remove(observer: DownloadManagerObserverable, forPath path: DownloadManagerDownloadPath) {
        observers[path]?.removeAll(where: { $0.id == observer.id })
    }

    private func loadActiveDownloads() {
        guard let savedDownloadsData = UserDefaults.standard.data(forKey: Strings.activeDownloads),
            let savedDownloads = try? JSONDecoder().decode([String: DownloadRequest].self, from: savedDownloadsData) else {
                return
        }
        for (key, value) in savedDownloads {
            activeDownloads[key] = value
        }
    }

    private func saveActiveDownloads() {
        let data = try? JSONEncoder().encode(activeDownloads)
        UserDefaults.standard.set(data, forKey: Strings.activeDownloads)
    }

//    /// Sets a delegate for a download
//    /// - parameter delegate: The delegate to set
//    /// - parameter key: The original download url as a string
//    func addDelegate(_ delegate: DownloadManagerDelegate, forKey key: String) {
//        delegates[key] = delegate
//    }
//
//    /// Removes a delegate for a download
//    /// - parameter key: The original download url as a string
//    func removeDelegate(forKey key: String) {
//        delegates[key] = nil
//    }

    // MARK: - URLSessionDelegate

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {

        guard let downloadPath = downloadTask.originalRequest?.url?.path else { return }
        guard let currentDownload = activeDownloads[downloadPath] else { return }

        if currentDownload.expectedContentLength == 0 {
            currentDownload.expectedContentLength = Int(totalBytesExpectedToWrite)
            saveActiveDownloads()
        }

        if let observers = observers[downloadPath] {
            observers.forEach { $0.downloadDidUpdate(currentDownload, downloaded: Int(totalBytesWritten)) }
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {

        guard let downloadPath = downloadTask.originalRequest?.url?.path else { return }
        guard let activeDownload = activeDownloads[downloadPath] else { return }

        do {
            activeDownloads[downloadPath] = nil
            saveActiveDownloads()
            guard let httpResponse = downloadTask.response as? HTTPURLResponse,
                (200...299).contains(httpResponse.statusCode) else {
                    print ("Server error when downloading file")
                    throw Errors.networkError
            }

            try saveDownload(activeDownload, tempLocation: location)

        } catch {
            print ("File error: \(error)")
            if let observers = self.observers[downloadPath] {
                observers.forEach { $0.downloadWasCompleted(for: downloadPath, response: .failed(error)) }
            }
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {

        guard let downloadPath = task.originalRequest?.url?.path else { return }
        guard let error = error else { return }

        activeDownloads[downloadPath] = nil
        saveActiveDownloads()
        if let observers = self.observers[downloadPath] {
            observers.forEach { $0.downloadWasCompleted(for: downloadPath, response: .failed(error)) }
        }
    }

    private func saveDownload(_ download: DownloadRequest, tempLocation: URL) throws {
        guard let saveUrl = download.saveUrl else { throw Errors.missingSaveUrl }

        if fileManager.fileExists(atPath: saveUrl.path) {
            try fileManager.removeItem(at: saveUrl)
        }
        try fileManager.moveItem(at: tempLocation, to: saveUrl)
        print("Saved item to: \(saveUrl)")

        if let observers = self.observers[download.downloadPath] {
            observers.forEach { $0.downloadWasCompleted(for: download.downloadPath, response: .success(download.saveUrlPath)) }
        }
    }
}
