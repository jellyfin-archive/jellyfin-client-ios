//
//  ItemViewController.swift
//  Emby Player
//
//  Created by Mats Mollestad on 29/08/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//

import UIKit
import SafariServices

protocol SingleItemStoreFetchable {
    func fetchItem(completion: @escaping (FetcherResponse<PlayableItem>) -> Void)
}

struct SingleItemStoreEmbyFetcher: SingleItemStoreFetchable {

    var itemId: String

    func fetchItem(completion: @escaping (FetcherResponse<PlayableItem>) -> Void) {

        guard let server = ServerManager.currentServer else {
            completion(.failed(ServerManager.Errors.unableToConnectToServer))
            return
        }

        server.fetchItemWith(id: itemId) { (response) in
            completion(FetcherResponse(response: response))
        }
    }
}

class SingleItemStore {
    let fetcher: SingleItemStoreFetchable
    var item: PlayableItem?

    init(fetcher: SingleItemStoreFetchable) {
        self.fetcher = fetcher
    }

    func fetchItem(completion: @escaping (FetcherResponse<Void>) -> Void) {
        fetcher.fetchItem { [weak self] (response) in

            var retResponse: FetcherResponse<Void> = .success(())
            switch response {
            case .failed(let error): retResponse = .failed(error)
            case .success(let item): self?.item = item
            }
            completion(retResponse)
        }
    }
}

protocol ItemViewControllerDelegate: class {
    func playItem(_ item: PlayableItem)
    func downloadItem(_ item: PlayableItem)
}

class ItemViewController: UIViewController, ContentViewControlling {

    var contentViewController: UIViewController { return self }

    var store: SingleItemStore

    private var externalLinksButtons                            = [UIButton]()

    lazy var supportedContainer: SupportedContainerController   = PlayerViewController.supportedContainers

    lazy var scrollView: UIScrollView                           = self.setUpScrollView()
    lazy var contentView: UIStackView                           = self.setUpContentView()
    lazy var imageView: UIImageView                             = self.setUpImageView()
    lazy var titleLabel: UILabel                                = self.setUpTitleLabel()
    lazy var actionsController: ItemActionsViewController       = self.createActionController()
    lazy var overviewTextView: UITextView                       = self.setUpOverviewTextView()
    lazy var seasonLabel: UILabel                               = self.setUpSeasonLabel()
    lazy var durationLabel: UILabel                             = self.setUpQualityLabel()
    lazy var qualityLabel: UILabel                              = self.setUpQualityLabel()
    lazy var generesLabel: UILabel                              = self.setUpQualityLabel()
    lazy var communityRatingLabel: UILabel                      = self.setUpQualityLabel()

    private var imageFetchTask: URLSessionTask?

    weak var delegate: ItemViewControllerDelegate?

    init(fetcher: SingleItemStoreFetchable) {
        self.store = SingleItemStore(fetcher: fetcher)
        super.init(nibName: nil, bundle: nil)
        setUpViewController()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("Decoder not implemented")
    }

    func fetchContent(completion: @escaping (FetcherResponse<Void>) -> Void) {
        store.fetchItem { (response) in
            DispatchQueue.main.async { [weak self] in
                self?.updateItem()
            }
            completion(response)
        }
        store.fetchItem(completion: completion)
    }

    private func setUpViewController() {
        view.addSubview(scrollView)
        scrollView.fillSuperView()
    }

    private func updateItem() {

        guard let item = store.item else { return }
        title = item.name
        titleLabel.text = item.name
        overviewTextView.text = item.overview
        seasonLabel.text = (item.seriesName ?? "") + " - " + (item.seasonName ?? "")
        durationLabel.text = "Duration: " + timeString(for: Double(item.runTime) / 10000000)

        if let videoStream = item.mediaStreams.first(where: { $0.type == "Video" }) {
            qualityLabel.text = "Video Quality: \(videoStream.displayTitle ?? ""), \(videoStream.aspectRatio ?? "")"
        }

        item.mediaSources.forEach { print($0.container) }
//        if item.mediaSources.contains(where: { supportedContainer.supports(container: $0.container) }) == false {
//            actionsController.disableDownload()
//        }
        
        seasonLabel.isHidden = item.seriesName == nil
        overviewTextView.isHidden = item.overview == nil
        qualityLabel.isHidden = item.mediaStreams.first == nil
        imageView.isHidden = true
        communityRatingLabel.isHidden = item.communityRating == nil

        if let genres = item.genres {
            generesLabel.text = String(genres.reduce("", { $0 + $1 + ", " }).dropLast(2))
        }

        if let communityRating = item.communityRating {
            communityRatingLabel.text = "Community Rating: \(communityRating)"
        }

        actionsController.itemId = item.id

        imageFetchTask?.cancel()
        if let imageUrl = item.imageUrl(with: .primary) {
            imageView.isHidden = false
            imageFetchTask = imageView.fetch(imageUrl) { [weak self] (_) in
                DispatchQueue.main.async {
                    self?.imageView.isHidden = true
                }
            }
        }
        addExternalLinks(for: item)
    }

    @objc
    func linkWasTapped(_ sender: UIButton) {
        guard let item = store.item,
            let externalLinks = item.externalLinks else { return }
        for link in externalLinks {
            if link.name == sender.title(for: .normal) {
                let webController = SFSafariViewController(url: link.url)
                present(webController, animated: true, completion: nil)
            }
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { [weak self] (_) in
            guard let unownedSelf = self else { return }
            let offset = unownedSelf.contentView.layoutMargins.left + unownedSelf.contentView.layoutMargins.right
            for button in unownedSelf.externalLinksButtons {
                button.imageEdgeInsets = UIEdgeInsets(top: 0, left: unownedSelf.view.bounds.width - offset - 30, bottom: 0, right: 0)
            }
        }
    }

    private func timeString(for duration: Double) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.zeroFormattingBehavior = [.pad]

        return formatter.string(from: duration) ?? ""
    }

    // MARK: - View Configs / Init

    private func setUpScrollView() -> UIScrollView {
        let view = UIScrollView()
        view.alwaysBounceVertical = true
        view.addSubview(contentView)
        contentView.fillSuperView()
        contentView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 1).isActive = true
        return view
    }

    private func setUpContentView() -> UIStackView {
        let views: [UIView] = [imageView, titleLabel, seasonLabel, actionsController.view, durationLabel, qualityLabel, generesLabel, communityRatingLabel, overviewTextView]
        let view = UIStackView(arrangedSubviews: views)
        view.axis = .vertical
        view.spacing = 10
        view.layoutMargins = UIEdgeInsets(top: 10, left: 20, bottom: 20, right: 20)
        view.isLayoutMarginsRelativeArrangement = true
        return view
    }

    private func createActionController() -> ItemActionsViewController {
        let controller = ItemActionsViewController()
        controller.delegate = self
        self.addChild(controller)
        controller.didMove(toParent: self)
        return controller
    }

    private func setUpTitleLabel() -> UILabel {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 26, weight: .bold)
        label.textColor = .white
        label.numberOfLines = 0
        return label
    }

    private func setUpImageView() -> UIImageView {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.heightAnchor.constraint(equalTo: view.widthAnchor, multiplier: 7/16).isActive = true
        return view
    }

    private func setUpOverviewTextView() -> UITextView {
        let view = UITextView()
        view.isScrollEnabled = false
        view.backgroundColor = .clear
        view.isEditable = false
        view.font = UIFont.systemFont(ofSize: 14)
        view.textColor = UIColor(white: 0.7, alpha: 1)
        return view
    }

    private func setUpSeasonLabel() -> UILabel {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        label.textColor = .white
        label.numberOfLines = 0
        return label
    }

    private func setUpQualityLabel() -> UILabel {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18)
        label.textColor = UIColor(white: 0.9, alpha: 1)
        label.numberOfLines = 0
        return label
    }

    private func addExternalLinks(for item: PlayableItem) {
        if let externalLinks = item.externalLinks,
            externalLinks.isEmpty == false {

            let externalLinksLabel = setUpQualityLabel()
            externalLinksLabel.text = "Links"
            contentView.addArrangedSubview(externalLinksLabel)

            for link in externalLinks {
                let button = UIButton(type: .system)
                button.setTitle(link.name, for: .normal)
                button.addTarget(self, action: #selector(linkWasTapped), for: .touchUpInside)
                button.titleLabel?.textAlignment = .left
                button.setImage(#imageLiteral(resourceName: "External Link"), for: .normal)
                button.semanticContentAttribute = .forceRightToLeft
                button.setTitleColor(UIColor(white: 0.7, alpha: 1), for: .normal)
                button.tintColor = UIColor(white: 0.7, alpha: 1)
                let offset = contentView.layoutMargins.left + contentView.layoutMargins.right
                button.imageEdgeInsets = UIEdgeInsets(top: 0, left: view.bounds.width - offset - 30, bottom: 0, right: 0)
                button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0)
                button.heightAnchor.constraint(greaterThanOrEqualToConstant: 50).isActive = true
                if #available(iOS 11, *) {
                    button.contentHorizontalAlignment = .trailing
                }
                externalLinksButtons.append(button)
                contentView.addArrangedSubview(button)
            }
        }
    }
}

extension ItemViewController: PlayerViewControllerDelegate {
    func playerWillDisappear(_ player: PlayerViewController) {

        DeviceRotateManager.shared.allowedOrientations = .allButUpsideDown
        guard let item = store.item, let userId = UserManager.shared.current?.id else { return }
        let fraction = player.currentTime.seconds / player.duration.seconds
        if fraction > 0.93 {
            ServerManager.currentServer?.markItemAsWatched(item, userId: userId)
        }
    }
}

extension ItemViewController: ItemActionViewControllerDelegate {
    func playItem() {
        guard let item = store.item else { return }
        delegate?.playItem(item)
    }

    func downloadItem() {
        guard let item = store.item else { return }
        delegate?.downloadItem(item)
    }
}

//
//extension ItemViewController: DownloadManagerDelegate {
//
//    func downloadDidUpdate(_ progress: DownloadRequest) {
//        DispatchQueue.main.async { [weak self] in
//            self?.downloadLabel.text = "Downloading: \((progress.progress * 1000).rounded(.down)/10)%"
//        }
//    }
//
//    func downloadWasCompleted(for downloadPath: String, response: FetcherResponse<String>) {
//        DispatchQueue.main.async { [weak self] in
//            switch response {
//            case .failed(_):
//                self?.downloadButton.setTitle("Download Failed", for: .normal)
//                self?.downloadLabel.text = "Ups, an error occured. This may be because the original file is unsupported as of now."
//            case .success(let url):
//                self?.downloadButton.setTitle("Download Completed", for: .normal)
//                guard var item = self?.store.item else { return }
//                print("Successfully downloaded: \(item.name)")
//                do {
//                    item.diskUrlPath = url
//                    try PlayableOfflineManager.shared.add(item)
//                } catch {
//                    print("Error adding item:", error)
//                }
//            }
//        }
//    }
//}
