//
//  ItemActionsViewController.swift
//  Emby Player
//
//  Created by Mats Mollestad on 01/10/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//

import UIKit

protocol ItemActionViewControllerDelegate: class {
    func playItem()
    func downloadItem()
}


/// A view controller presenting the different actions that can be taken on a item
class ItemActionsViewController: UIViewController {
    
    private struct Strings {
        static let playTitle        = "Play"
        static let downloadTitle    = "Download"
        static let downloadingTitle = "Downloading"
        static let deleteTitle      = "Delete"
    }
    
    var itemId: String? { didSet { updateDownloadStatus() } }
    
    weak var delegate: ItemActionViewControllerDelegate?
    
    var itemDownloadManager: ItemDownloadManager = .shared
    var downloadedItemManager: PlayableOfflineManager = .shared
    
    lazy var contentView: UIStackView   = self.createContentView()
    lazy var playButton: UIButton       = self.createButton(title: Strings.playTitle, color: .green, selector: #selector(self.playWasTapped))
    lazy var downloadButton: UIButton   = self.createButton(title: Strings.downloadTitle, color: .orange, selector: #selector(self.downloadWasTapped))
    lazy var downloadLabel: UILabel     = self.createDownloadLabel()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewController()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let itemId = itemId {
            ItemDownloadManager.shared.add(self, forItemId: itemId)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let itemId = itemId {
            ItemDownloadManager.shared.remove(observer: self, forItemId: itemId)
        }
    }
    
    @objc func playWasTapped() {
        delegate?.playItem()
    }
    
    @objc func downloadWasTapped() {
        delegate?.downloadItem()
        updateDownloadStatus()
    }
    
    
    private func setupViewController() {
        view.addSubview(contentView)
        contentView.fillSuperView()
    }
    
    private func updateDownloadStatus() {
        guard let itemId = itemId else { return }
        downloadLabel.isHidden = true
        
        if downloadedItemManager.getItemWith(id: itemId) != nil {
            downloadButton.setTitle(Strings.deleteTitle, for: .normal)
            
        } else if itemDownloadManager.activeDownloads[itemId] != nil {
            downloadButton.setTitle(Strings.downloadingTitle, for: .normal)
            downloadButton.isEnabled = false
        }
    }
    
    // MARK: - Creating the views
    
    private func createDownloadLabel() -> UILabel {
        let view = UILabel()
        view.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        view.textColor = .white
        view.isHidden = true
        return view
    }
    
    private func createButton(title: String, color: UIColor, selector: Selector) -> UIButton {
        let view = UIButton()
        view.backgroundColor = color
        view.setTitle(title, for: .normal)
        view.setTitleColor(.black, for: .normal)
        view.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        view.layer.cornerRadius = 8
        view.heightAnchor.constraint(equalToConstant: 50).isActive = true
        view.addTarget(self, action: selector, for: .touchUpInside)
        return view
    }
    
    private func createContentView() -> UIStackView {
        let subviews = [playButton, downloadButton, downloadLabel]
        let view = UIStackView(arrangedSubviews: subviews)
        view.spacing = 10
        view.axis = .vertical
        return view
    }
}


extension ItemActionsViewController: DownloadManagerObserverable {
    
    func downloadDidUpdate(_ progress: DownloadRequest) {
        DispatchQueue.main.async { [weak self] in
            self?.downloadLabel.isHidden = false
            self?.downloadLabel.text = "Download Progress: \(Double(Int(progress.progress*1000))/10)%"
        }
    }
    
    func downloadWasCompleted(for downloadPath: String, response: FetcherResponse<String>) {
        DispatchQueue.main.async { [weak self] in
            self?.downloadLabel.isHidden = true
            self?.updateDownloadStatus()
        }
    }
}
