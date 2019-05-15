//
//  ErrorViewController.swift
//  Emby Player
//
//  Created by Mats Mollestad on 26/08/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//

import UIKit

class ErrorViewController: UIViewController {

    let error: Error
    var resolvHandler: (() -> Void)

    lazy var contentView: UIStackView = self.setUpContentView()
    lazy var errorTitle: UILabel = self.setUpErrorLabel()
    lazy var errorDescription: UITextView = self.setUpErrorDescription()
    lazy var resolvButton: UIButton = self.setUpResolvButton()

    init(error: Error, resolvHandler: @escaping (() -> Void)) {
        self.error = error
        self.resolvHandler = resolvHandler
        print("Error: ", error)
        super.init(nibName: nil, bundle: nil)
        setUpViewController()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUpViewController() {
        view.backgroundColor = .clear
        view.addSubview(contentView)
        contentView.centerInSuperview()
        contentView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 1).isActive = true
    }

    private func setUpContentView() -> UIStackView {
        let views = [errorTitle, errorDescription, resolvButton]
        let view = UIStackView(arrangedSubviews: views)
        view.axis = .vertical
        view.spacing = 20
        return view
    }

    private func setUpErrorLabel() -> UILabel {
        let label = UILabel()
        label.text = "Ups, an error occured"
        label.textAlignment = .center
        label.textColor = .white
        return label
    }

    private func setUpErrorDescription() -> UITextView {
        let textView = UITextView()
        textView.textAlignment = .center
        textView.isScrollEnabled = false
        textView.isEditable = false
        textView.text = error.localizedDescription
        textView.backgroundColor = .clear
        textView.textColor = .white
        return textView
    }

    private func setUpResolvButton() -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle("Try Again", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        button.addTarget(self, action: #selector(resolvWasTapped), for: .touchUpInside)
        return button
    }

    @objc
    private func resolvWasTapped() {
        resolvHandler()
    }
}
