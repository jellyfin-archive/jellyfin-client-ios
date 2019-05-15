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
        static let unableToDownload = "Unable To Download"
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
    }

    private func setupViewController() {
        view.addSubview(contentView)
        contentView.fillSuperView()
    }

    func updateDownloadStatus() {
        guard let itemId = itemId else { return }
        downloadLabel.textColor = .white
        downloadButton.backgroundColor = .orange

        if downloadedItemManager.getItemWith(id: itemId) != nil {
            downloadButton.setTitle(Strings.deleteTitle, for: .normal)
            downloadButton.backgroundColor = .red
            downloadButton.alpha = 1
        } else if itemDownloadManager.activeDownloads[itemId] != nil {
            downloadButton.setTitle(Strings.downloadingTitle, for: .normal)
            downloadButton.alpha = 0.7
            downloadButton.isEnabled = false
        }
    }

    func present(_ error: Error) {
        updateDownloadStatus()
        downloadLabel.isHidden = false
        downloadLabel.textColor = .red
        downloadLabel.text = "Error: \(error.localizedDescription)"
    }

    func disableDownload() {
        downloadLabel.textColor = .white
        downloadButton.isEnabled = false
        downloadButton.alpha = 0.7
        downloadButton.backgroundColor = .orange
        downloadButton.setTitle(Strings.unableToDownload, for: .normal)
    }

    // MARK: - Creating the views

    private func createDownloadLabel() -> UILabel {
        let view = UILabel()
        view.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        view.textColor = .white
        view.isHidden = true
        view.numberOfLines = 2
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
    func downloadDidUpdate(_ progress: DownloadRequest, downloaded: Int) {
        DispatchQueue.main.async { [weak self] in
            self?.downloadLabel.isHidden = false
            self?.downloadLabel.text = "Download Progress: \(Double(downloaded*1000/progress.expectedContentLength)/10)%"
        }
    }

    func downloadWasCompleted(for downloadPath: String, response: FetcherResponse<String>) {
        DispatchQueue.main.async { [weak self] in
            switch response {
            case .success:
                self?.downloadLabel.isHidden = true
                self?.updateDownloadStatus()

            case .failed(let error):
                self?.present(error)
            }
        }
    }
}
