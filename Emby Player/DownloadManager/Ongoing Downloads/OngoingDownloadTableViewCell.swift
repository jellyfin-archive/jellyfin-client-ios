//
//  OngoingDownloadTableViewCell.swift
//  Emby Player
//
//  Created by Mats Mollestad on 28/09/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//

import UIKit

/// A table view cell that presents a ongoing download
class OngoingDownloadTableViewCell: UITableViewCell {

    var item: PlayableIteming? {
        didSet {
            if let item = item {
                titleLabel.text = item.name
            }
        }
    }

    lazy var titleLabel: UILabel = self.createLabel(fontSize: 20, fontWeight: .bold, alpha: 1)
    lazy var totalSizeLabel: UILabel = self.createLabel(fontSize: 16, fontWeight: .medium, alpha: 0.8)
    lazy var progressView: UIProgressView = self.createProgressView()
    lazy var progressLabel: UILabel = self.createLabel(fontSize: 16, fontWeight: .medium, alpha: 0.8)
    lazy var stopButton: UIButton = self.createStopButton()

    lazy var horizontalStackView: UIStackView = self.createContentView(subviews: [self.progressView, self.progressLabel, self.stopButton], axis: .horizontal, alignment: .center)
    lazy var verticalStackView: UIStackView = self.createContentView(subviews: [self.titleLabel, self.totalSizeLabel, self.horizontalStackView], axis: .vertical, alignment: .fill)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupViews()
    }

    private func setupViews() {
        backgroundColor = .black
        addSubview(verticalStackView)
        verticalStackView.fillSuperView()
        selectionStyle = .none
    }

    func updateContent(progress: DownloadProgressable, written: Int) {
        let progressValue = progress.progress(with: written)
        progressView.progress = Float(progressValue)
        totalSizeLabel.text = "\(string(fromBytes: written)) of \(string(fromBytes: progress.expectedContentLength))"

        if !progressValue.isNaN {
            progressLabel.text = "\(Double(Int(progressValue*1000))/10)%"
        } else {
            progressLabel.text = "Not started"
        }
    }

    private func string(fromBytes bytes: Int) -> String {
        return ByteCountFormatter().string(fromByteCount: Int64(truncating: NSNumber(value: bytes)))
    }

    @objc func stopButtonWasTapped() {
        guard let itemId = item?.id else { return }
        ItemDownloadManager.shared.cancleDownload(forItemId: itemId)
        totalSizeLabel.text = "Stopped"
    }

    // MARK: - View Setup

    private func createContentView(subviews: [UIView], axis: NSLayoutConstraint.Axis, alignment: UIStackView.Alignment) -> UIStackView {
        let view = UIStackView(arrangedSubviews: subviews)
        view.axis = axis
        view.spacing = 10
        view.layoutMargins = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        view.isLayoutMarginsRelativeArrangement = true
        view.alignment = alignment
        return view
    }

    private func createProgressView() -> UIProgressView {
        let view = UIProgressView()
        view.progressTintColor = .green
        view.trackTintColor = .white
        return view
    }

    private func createLabel(fontSize: CGFloat, fontWeight: UIFont.Weight, alpha: CGFloat) -> UILabel {
        let view = UILabel()
        view.font = UIFont.systemFont(ofSize: fontSize, weight: fontWeight)
        view.textColor = .white
        view.alpha = alpha
        return view
    }

    private func createTitleLabel() -> UILabel {
        let view = UILabel()
        view.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        view.textColor = .white
        view.numberOfLines = 2
        return view
    }

    private func createProgressLabel() -> UILabel {
        let view = UILabel()
        view.font = UIFont.systemFont(ofSize: 16)
        view.textColor = .white
        view.alpha = 0.8
        view.heightAnchor.constraint(equalToConstant: 4).isActive = true
        return view
    }

    private func createStopButton() -> UIButton {
        let view = UIButton(type: .system)
        let image = UIImage(named: "stop")
        view.setImage(image, for: .normal)
        view.tintColor = .red
        view.addTarget(self, action: #selector(stopButtonWasTapped), for: .touchUpInside)
        return view
    }
}

extension OngoingDownloadTableViewCell: DownloadManagerObserverable {
    func downloadDidUpdate(_ progress: DownloadRequest, downloaded: Int) {
        DispatchQueue.main.async { [weak self] in
            self?.updateContent(progress: progress, written: downloaded)
        }
    }

    func downloadWasCompleted(for downloadPath: String, response: FetcherResponse<String>) {
        DispatchQueue.main.async { [weak self] in
            switch response {
            case .success:
                self?.totalSizeLabel.text = "The download has been completed!"
                self?.progressView.progress = 1
                self?.progressLabel.text = "100%"

            case .failed(let error):
                self?.totalSizeLabel.text = "An error cooured: \(error.localizedDescription)"
                self?.progressView.progress = 0
                self?.progressLabel.text = "NaN"
            }
        }
    }
}
