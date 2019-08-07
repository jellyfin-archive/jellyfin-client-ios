//
//  QualitySelectorViewController.swift
//  Emby Player
//
//  Created by Mats Mollestad on 07/08/2019.
//  Copyright © 2019 Mats Mollestad. All rights reserved.
//

import UIKit

protocol QualitySelectorViewControllerDelegate : class {
    func didSelect(_ quality: QualitySelectorViewController.Quality, in picker: QualitySelectorViewController)
}


class QualitySelectorViewController : UIViewController {

    var item: PlayableIteming?
    weak var delegate: QualitySelectorViewControllerDelegate?
    var selectedQualityIndex: Int = 0

    lazy var bitrateLabel = ViewBuilder.textLabel(isHidden: true, text: "Bitrate")
    lazy var bitrateTextField = ViewBuilder.textField(placeholder: "1500000", keybordType: .numberPad)

    struct Quality : Equatable {

        static let custom = Quality(bitrate: "", title: "Custom")

        let bitrate: String
        let title: String
    }

    override func viewDidLoad() {
        title = "Select Quality"
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(dismissViewController))

        let contentView = ViewBuilder.stackView(
            arrangedSubviews: [
            ViewBuilder.textLabel(text: "Quality Options"),
            ViewBuilder.picker(dataSource: self, delegate: self),
            bitrateLabel,
            bitrateTextField,
            ViewBuilder.button(title: "Select Quality", color: .green, target: self, selector: #selector(selectQuality))
        ],
            spacing: 10,
            layoutMargins: UIEdgeInsets(top: 10, left: 20, bottom: 20, right: 20)
        )
        let scrollView = ViewBuilder.scrollView(subview: contentView)
        view.addSubview(scrollView)
        view.backgroundColor = .black
        scrollView.fillSuperView()
        bitrateTextField.isHidden = true
    }

    private var options: [Quality] {
        guard let item = item else { return [] }
        guard let bitrate = item.mediaStreams.first?.bitRate else { return [] }

        let standardBitrates = [
            15000000,
            12000000,
            8000000,
            4000000,
            1500000,
        ]

        return [
            Quality(bitrate: "\(bitrate)", title: "Original"),
            .custom
            ] +
            standardBitrates
                .filter({ $0 <= bitrate })
                .map { Quality(bitrate: "\($0)", title: "\(Double($0)/1000000) Mbps") }
    }

    @objc
    func selectQuality() {
        if let quality = selectedQuality {
            delegate?.didSelect(quality, in: self)
        }
        self.dismiss(animated: true, completion: nil)
    }

    @objc
    func dismissViewController() {
        dismiss(animated: true, completion: nil)
    }

    var selectedQuality: Quality? {
        if selectedQualityIndex < options.count {
            return options[selectedQualityIndex]
        } else {
            return nil
        }
    }

    private func updateSelection(from row: Int) {
        selectedQualityIndex = row
        bitrateTextField.isHidden = selectedQuality != .custom
        bitrateLabel.isHidden = selectedQuality != .custom
    }
}

extension QualitySelectorViewController : UIPickerViewDelegate, UIPickerViewDataSource {

//    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
//        options[row].title
//    }

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return options.count
    }

    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        NSAttributedString(string: options[row].title, attributes: [.foregroundColor : UIColor.white])
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        updateSelection(from: row)
    }
}
