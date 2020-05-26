/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */
//
//  CustomServerSelectionViewController.swift
//  Jellyfin Player
//
//  Created by Mats Mollestad on 24/09/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//

import UIKit

struct ServerConnection: Codable {
    let ipAddress: String
    let port: Int
}

protocol CustomServerSelectionViewControllerDelegate: class {
    func connectToServer(_ server: ServerConnection)
}

class CustomServerSelectionViewController: UIViewController {

    private struct Strings {
        static let missingIPTitle           = "Missing IP Address"
        static let invalidPortTitle         = "Invalid Server Port"
        static let serverAddressLabel       = "Server address"
        static let serverAddressPlaceholder = "https://your-server.com"
        static let serverPortLabel          = "Server Port"
        static let serverPortPlaceholder    = "8096"
        static let connectTitle             = "Connect to Server"

    }

    enum Errors: LocalizedError {
        case missingIP
        case invalidServerPort

        public var errorDescription: String? {
            switch self {
            case .missingIP:            return Strings.missingIPTitle
            case .invalidServerPort:    return Strings.invalidPortTitle
            }
        }
    }

    lazy var scrollView: UIScrollView       = ViewBuilder.scrollView(subview: self.contentView)
    lazy var contentView: UIStackView       = ViewBuilder.stackView(arrangedSubviews: [self.serverIPLabel,
                                                                                       self.serverIPField,
                                                                                       self.serverPortLabel,
                                                                                       self.serverPortField,
                                                                                       self.errorTextLabel,
                                                                                       self.connectButton],
                                                                    layoutMargins: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20))

    lazy var serverIPLabel                  = ViewBuilder.textLabel(font: .title3,
                                                                    text: Strings.serverAddressLabel)
    lazy var serverIPField: UITextField     = ViewBuilder.textField(placeholder: Strings.serverAddressPlaceholder,
                                                                    text: "",
                                                                    keybordType: .URL)

    lazy var serverPortLabel                = ViewBuilder.textLabel(font: .title3,
                                                                    text: Strings.serverPortLabel)
    lazy var serverPortField: UITextField   = ViewBuilder.textField(placeholder: Strings.serverPortPlaceholder,
                                                                    keybordType: .numberPad)

    lazy var errorTextLabel: UILabel        = ViewBuilder.textLabel(textColor: .red,
                                                                    font: .callout,
                                                                    isHidden: true)

    lazy var connectButton: UIButton        = ViewBuilder.button(title: Strings.connectTitle,
                                                                 color: UIColor(red: 20/255, green: 200/255, blue: 20/255, alpha: 1),
                                                                 target: self,
                                                                 selector: #selector(self.connectButtonWasTapped))

    weak var delegate: CustomServerSelectionViewControllerDelegate?

    override func viewDidLoad() {
        setupViewController()
    }

    private func setupViewController() {
        title = "Custom Connection"
        view.backgroundColor = .black
        view.addSubview(scrollView)
        scrollView.fillSuperView()
    }

    private func getServerConnection() throws -> ServerConnection {

        guard var ipAddress = serverIPField.text,
            !ipAddress.isEmpty else { throw Errors.missingIP }
        if !ipAddress.contains(":") {
            ipAddress = "http://" + ipAddress
        }
        let portString = serverPortField.text?.isEmpty == true ? Strings.serverPortPlaceholder : serverPortField.text!
        guard let port = Int(portString) else { throw Errors.invalidServerPort }

        return ServerConnection(ipAddress: ipAddress, port: port)
    }

    func presentError(_ error: Error) {
        errorTextLabel.text = error.localizedDescription
        errorTextLabel.isHidden = false
    }

    @objc
    func connectButtonWasTapped() {
        do {
            let connection = try getServerConnection()
            delegate?.connectToServer(connection)
        } catch {
            presentError(error)
        }
    }
}
