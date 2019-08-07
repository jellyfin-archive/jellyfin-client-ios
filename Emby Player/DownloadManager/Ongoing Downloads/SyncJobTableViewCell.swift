//
//  SyncJobTableViewCell.swift
//  Emby Player
//
//  Created by Mats Mollestad on 02/08/2019.
//  Copyright © 2019 Mats Mollestad. All rights reserved.
//

import UIKit

class SyncJobTableViewCell: UITableViewCell {

    var job: SyncManager.ActiveJob? {
        didSet {
            updateViews()
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

    @objc
    func stopButtonWasTapped() {
        guard let job = job else { return }
        SyncManager.shared.cancel(job)
        totalSizeLabel.text = "Canceled"
    }

    func updateViews() {
        guard let job = job else { return }
        titleLabel.text = job.item.name
        totalSizeLabel.text = job.job.quality

        let progressValue = job.job.progress
        progressView.progress = Float(job.job.progress / 100)

        switch job.job.status {
        case .converting: progressLabel.text = "\(Double(Int(progressValue*10))/10)%"
        default: progressLabel.text = job.job.status.rawValue
        }
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
