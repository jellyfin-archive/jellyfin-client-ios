/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */
//
//  HLSDownloadManager.swift
//  Emby Player
//
//  Created by Mats Mollestad on 11/09/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//

import Foundation

//class HLSItemDownload {
//    let downloadUrl: URL
//    let saveUrlPath: String
//    let mainFileId: String
//    let mainFile: HLSFile
//    let itemIndex: Int
//    var item: HLSItem { return mainFile.items[itemIndex] }
//
//    init(downloadUrl: URL, saveUrlPath: String, mainFileId: String, mainFile: HLSFile, itemIndex: Int) {
//        self.downloadUrl = downloadUrl
//        self.saveUrlPath = saveUrlPath
//        self.mainFileId = mainFileId
//        self.mainFile = mainFile
//        self.itemIndex = itemIndex
//    }
//}
//
//
//class HLSDownloadManager: NSObject, URLSessionDelegate {
//
//
//    private struct Constants {
//        static let maxActiveDownloads: Int = 5
//    }
//
//    static let shared = HLSDownloadManager()
//
//    var downloadStack = Stack<HLSItemDownload>()
//    var activeItemDownloads = [HLSItemDownload]()
//    var activeDownloads = [String : DownloadProgress]()
//    var activeFiles = [String : HLSFile]()
//
//
//    func startDownload(from downloadUrl: URL, to saveUrlPath: String) {
//
//        let progress = DownloadProgress(downloadPath: downloadUrl.absoluteString, expectedContentLength: 0, saveUrlPath: saveUrlPath)
//        activeDownloads[saveUrlPath] = progress
//
//        let requester = NetworkRequester()
//        _ = requester.getData(from: downloadUrl) { [weak self] (response) in
//            switch response {
//            case .failed(let error): print("Error downloading HLS:", error)
//            case .success(let fileData): self?.saveHLSMainFile(fileData, downloadUrl: downloadUrl, saveUrlPath: saveUrlPath)
//
//            }
//        }
//    }
//
//    private func saveHLSMainFile(_ fileData: Data, downloadUrl: URL, saveUrlPath: String) {
//        do {
//            print("Successfully downloaded hls file")
//            let documentDirectory = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
//            let saveUrl = documentDirectory.appendingPathComponent(saveUrlPath)
//            let hlsFile = try HLSDecoder().decode(data: fileData, encoding: .utf8)
//            try hlsFile.writeToFile(at: saveUrl)
//            activeFiles[saveUrlPath] = hlsFile
//
//            let hlsDirectory = saveUrl.deletingLastPathComponent().appendingPathComponent("hls1")
//            if !FileManager.default.fileExists(atPath: hlsDirectory.path) {
//                try FileManager.default.createDirectory(at: hlsDirectory, withIntermediateDirectories: false, attributes: nil)
//            }
//            let mainDirectory = hlsDirectory.appendingPathComponent("main")
//            print("Main Dire: ", mainDirectory)
//            if !FileManager.default.fileExists(atPath: mainDirectory.path) {
//                try FileManager.default.createDirectory(at: mainDirectory, withIntermediateDirectories: false, attributes: nil)
//            }
//
//            downloadItems(for: hlsFile, mainUrl: downloadUrl, mainSaveUrlPath: saveUrlPath)
//        } catch {
//            print("Error decoding HLS:", error)
//        }
//    }
//
//    private func downloadItems(for file: HLSFile, mainUrl: URL, mainSaveUrlPath: String) {
//
//        guard let mainSaveUrl = URL(string: mainSaveUrlPath) else { return }
//        let mainDownloadDirectory = mainUrl.deletingLastPathComponent()
//        var urlPath = mainSaveUrl.deletingLastPathComponent().absoluteString
//        if urlPath == "./" {
//            urlPath = ""
//        }
//
//        activeDownloads[mainSaveUrlPath]?.expectedContentLength += Int(file.items.reduce(0) { $0 + $1.lenght })
//
//        for j in 0..<file.items.count {
//            let i = file.items.count - 1 - j
//            let item = file.items[i]
//            var downloadUrl = mainDownloadDirectory.appendingPathComponent(item.urlPath)
//            if var downloadComponent = URLComponents(url: downloadUrl, resolvingAgainstBaseURL: false) {
//                downloadComponent.queryItems = item.urlQueryItems
//                downloadUrl = downloadComponent.url ?? downloadUrl
//            }
//
//            let saveUrlPath: String = urlPath.isEmpty ? item.urlPath : urlPath.appending(item.urlPath)
//
//            let download = HLSItemDownload(downloadUrl: downloadUrl, saveUrlPath: saveUrlPath, mainFileId: mainSaveUrlPath, mainFile: file, itemIndex: i)
//            downloadStack.add(download)
//        }
//
//        while !downloadStack.isEmpty && activeItemDownloads.count < Constants.maxActiveDownloads {
//            startDownload()
//        }
//    }
//
//
//    private func startDownload() {
//
//        guard activeItemDownloads.count < Constants.maxActiveDownloads else { return }
//        guard let downloadItem = downloadStack.pop() else { return }
//        activeItemDownloads.append(downloadItem)
//
//        DownloadManager.shared.startDownload(from: downloadItem.downloadUrl, to: downloadItem.saveUrlPath, with: NetworkRequester.defaultHeader, didUpdate: {(_) in }) { [weak self] (response) in
//            switch response {
//            case .failed(let error): print(error)
//            case .success(let urlPath):
//                print("Successfully downloaded file: ", urlPath)
//                self?.activeItemDownloads.removeAll(where: { $0.item == downloadItem.item })
//                self?.activeDownloads[downloadItem.mainFileId]?.writtenBytes += Int(downloadItem.item.lenght)
//                if let progress = self?.activeDownloads[downloadItem.mainFileId] {
//                    progress.didUpdate(progress)
//                    if progress.progress >= 1 {
//                        progress.completion(.success(downloadItem.mainFileId))
//                        self?.activeFiles[downloadItem.mainFileId] = nil
//                        self?.activeDownloads[downloadItem.mainFileId] = nil
//                    } else {
//                        self?.startDownload()
//                    }
//                }
//            }
//        }
//    }
//}
