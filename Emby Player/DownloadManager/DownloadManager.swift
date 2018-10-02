//
//  DownloadManager.swift
//  Emby Player
//
//  Created by Mats Mollestad on 07/09/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//

import Foundation

protocol DownloadManagerObserverable {
    var id: String { get }
    func downloadDidUpdate(_ progress: DownloadRequest)
    func downloadWasCompleted(for downloadPath: DownloadManagerDownloadPath, response: FetcherResponse<DownloadManagerLocalPath>)
}

extension DownloadManagerObserverable {
    var id: String { return String(describing: type(of: self)) }
    func downloadDidUpdate(_ progress: DownloadRequest) {}
    func downloadWasCompleted(for downloadPath: DownloadManagerDownloadPath, response: FetcherResponse<DownloadManagerLocalPath>) {}
}


protocol DownloadProgressable {
    var writtenBytes: Int { get }
    var expectedContentLength: Int { get }
    var progress: Double { get }
}

typealias DownloadManagerLocalPath = String
typealias DownloadManagerDownloadPath = String


class DownloadRequest: DownloadProgressable, Hashable {
    
    /// The url used to download the item
    /// Used to id which DownloadRequest to update on URLSessionDelegate
    let downloadPath: String
    var writtenBytes: Int = 0
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
    
    var progress: Double {
        return Double(writtenBytes) / Double(expectedContentLength)
    }
    
    init(downloadPath: String, expectedContentLength: Int, saveUrlPath: String) {
        self.downloadPath = downloadPath
        self.expectedContentLength = expectedContentLength
        self.saveUrlPath = saveUrlPath
    }
    
    static func == (lhs: DownloadRequest, rhs: DownloadRequest) -> Bool {
        return lhs.downloadPath == rhs.downloadPath && lhs.saveUrl == rhs.saveUrl
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(downloadPath)
        hasher.combine(saveUrl)
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
    }
    
    enum Errors: Error {
        case networkError
        case unknownError
        case missingSaveUrl
    }
    
    static let shared = DownloadManager()
    
    var activeDownloads = [String : DownloadRequest]()
    private var observers = [DownloadManagerDownloadPath : [DownloadManagerObserverable]]()
    private let sessionConfig = URLSessionConfiguration.background(withIdentifier: String(describing: DownloadManager.self))
    
    override init() {
        super.init()
        URLSession(configuration: sessionConfig, delegate: self, delegateQueue: nil).getAllTasks { (tasks) in
            tasks.forEach { $0.cancel() }
        }
    }
    
    
    /// Starts downloading a file from an url
    /// - parameter downloadUrl: The url to download from
    /// - parameter saveUrlPath: The path to save the file to
    /// - parameter headers: The headers needed to download the file
    func startDownload(from downloadUrl: URL, to saveUrlPath: String, with headers: NetworkRequesterHeader) {
        
        let progress = DownloadRequest(downloadPath: downloadUrl.path, expectedContentLength: 0, saveUrlPath: saveUrlPath)
        activeDownloads[progress.downloadPath] = progress
        
        let body: String? = nil
        let requester = NetworkRequester()
        requester.sessionDelegate = self
        requester.sessionConfig = sessionConfig
        requester.downloadFile(from: downloadUrl, header: headers, body: body)
    }
    
    
    func add(observer: DownloadManagerObserverable, forPath path: DownloadManagerDownloadPath) {
        observers[path] = (observers[path] ?? []) + [observer]
    }
    
    func remove(observer: DownloadManagerObserverable, forPath path: DownloadManagerDownloadPath) {
        observers[path]?.removeAll(where: { $0.id == observer.id })
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
        
        currentDownload.writtenBytes = Int(totalBytesWritten)
        currentDownload.expectedContentLength = Int(totalBytesExpectedToWrite)
        
        if let observers = self.observers[downloadPath] {
            observers.forEach { $0.downloadDidUpdate(currentDownload) }
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        
        guard let downloadPath = downloadTask.originalRequest?.url?.path else { return }
        guard let activeDownload = activeDownloads[downloadPath] else { return }
        
        do {
            activeDownloads[downloadPath] = nil
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
    
    
    private func saveDownload(_ download: DownloadRequest, tempLocation: URL) throws {
        guard let saveUrl = download.saveUrl else { throw Errors.missingSaveUrl }
        
        let fileManager = FileManager.default
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
