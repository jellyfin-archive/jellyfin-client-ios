//
//  DownloadManager.swift
//  Emby Player
//
//  Created by Mats Mollestad on 07/09/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//

import Foundation

protocol DownloadManagerDelegate: class {
    func downloadDidUpdate(_ progress: DownloadProgress)
    func downloadWasCompleted(_ response: FetcherResponse<String>)
}

class DownloadProgress: Hashable {
    
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
    
    static func == (lhs: DownloadProgress, rhs: DownloadProgress) -> Bool {
        return lhs.downloadPath == rhs.downloadPath && lhs.saveUrl == rhs.saveUrl
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(downloadPath)
        hasher.combine(saveUrl)
    }
}


typealias DownloadManagerObserver = (DownloadProgress) -> Void


struct DownloadInformation<T: Codable & Hashable>: Codable, Hashable {
    let id: String
    let lastPathConponent: String
    let item: T
}


class DownloadManager: NSObject, URLSessionDownloadDelegate {
    
    static let shared = DownloadManager()
    
    var activeDownloads = [String : DownloadProgress]()
    private var delegates = [String : DownloadManagerDelegate]()
    
    
    func startDownload(from downloadUrl: URL, to saveUrlPath: String, with headers: NetworkRequesterHeader) {
        
        let progress = DownloadProgress(downloadPath: downloadUrl.path, expectedContentLength: 0, saveUrlPath: saveUrlPath)
        activeDownloads[progress.downloadPath] = progress
        
        let body: String? = nil
        let requester = NetworkRequester()
        requester.sessionDelegate = self
        requester.sessionConfig = URLSessionConfiguration.background(withIdentifier: progress.downloadPath)
        requester.downloadFile(from: downloadUrl, header: headers, body: body)
    }
    
    
    func addDelegate(_ delegate: DownloadManagerDelegate, forKey key: String) {
        delegates[key] = delegate
    }
    
    func removeDelegate(forKey key: String) {
        delegates[key] = nil
    }
    
    
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        
        guard let downloadPath = session.configuration.identifier else { return }
        guard let currentDownload = activeDownloads[downloadPath] else { return }
        
        currentDownload.writtenBytes = Int(totalBytesWritten)
        currentDownload.expectedContentLength = Int(totalBytesExpectedToWrite)
        
        delegates[currentDownload.downloadPath]?.downloadDidUpdate(currentDownload)
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        
        do {
            guard let downloadPath = session.configuration.identifier else { return }
            guard let activeDownload = activeDownloads[downloadPath],
                let saveUrl = activeDownload.saveUrl else { return }
            activeDownloads[downloadPath] = nil
            guard let httpResponse = downloadTask.response as? HTTPURLResponse,
                (200...299).contains(httpResponse.statusCode) else {
                    print ("Server error when downloading file")
                    return
            }
            print("Saving to url:", saveUrl)
            if FileManager.default.fileExists(atPath: saveUrl.absoluteString) {
                try FileManager.default.removeItem(at: saveUrl)
            }
            try FileManager.default.moveItem(at: location, to: saveUrl)
            delegates[activeDownload.downloadPath]?.downloadWasCompleted(.success(activeDownload.saveUrlPath))
        } catch {
            print ("File error: \(error)")
        }
    }
}
