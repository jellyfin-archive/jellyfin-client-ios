//
//  CustomServerSelectionViewController.swift
//  Emby Player
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
        static let missingIPTitle       = "Missing IP Address"
        static let missingPortTitle     = "Missing Server Port"
        static let ipAddressPlaceholder = "10.0.0.27"
        static let portPlaceholder      = "8096"
        static let connectTitle         = "Connect to Server"
    }
    
    enum Errors: LocalizedError {
        case missingIP
        case missingPort
        
        public var errorDescription: String? {
            switch self {
            case .missingIP:    return Strings.missingIPTitle
            case .missingPort:  return Strings.missingPortTitle
            }
        }
    }
    
    lazy var scrollView: UIScrollView       = self.createScrollView()
    lazy var contentView: UIStackView       = self.createStackView()
    lazy var serverIPField: UITextField     = self.createTextField(placeholder: Strings.ipAddressPlaceholder, text: "", keybordType: .URL)
    lazy var serverPortField: UITextField   = self.createTextField(placeholder: Strings.portPlaceholder, text: "8096", keybordType: .numberPad)
    lazy var errorTextLabel: UILabel        = self.createErrorTextLabel()
    lazy var connectButton: UIButton        = self.createButton(title: Strings.connectTitle, color: .green, selector: #selector(self.connectButtonWasTapped))
    
    weak var delegate: CustomServerSelectionViewControllerDelegate?
    
    override func viewDidLoad() {
        setupViewController()
    }
    
    private func setupViewController() {
        title = "Custom Connection"
        view.backgroundColor = .white
        view.addSubview(scrollView)
        scrollView.fillSuperView()
    }
    
    private func getServerConnection() throws -> ServerConnection {
        
        guard let ip = serverIPField.text, !ip.isEmpty                          else { throw Errors.missingIP }
        guard let portString = serverPortField.text, let port = Int(portString) else { throw Errors.missingPort }
        
        return ServerConnection(ipAddress: ip, port: port)
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
    
    
    // MARK: - View Setup
    
    private func createScrollView() -> UIScrollView {
        let view = UIScrollView()
        view.keyboardDismissMode = .onDrag
        view.addSubview(contentView)
        contentView.fillSuperView()
        contentView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 1).isActive = true
        return view
    }
    
    private func createStackView() -> UIStackView {
        let arrangedViews = [serverIPField, serverPortField, errorTextLabel, connectButton]
        let view = UIStackView(arrangedSubviews: arrangedViews)
        view.spacing = 10
        view.axis = .vertical
        view.layoutMargins = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        view.isLayoutMarginsRelativeArrangement = true
        return view
    }
    
    private func createTextField(placeholder: String, text: String, keybordType: UIKeyboardType) -> UITextField {
        let view = VisibleTextField()
        view.placeholder = placeholder
        view.text = text
        view.borderStyle = .roundedRect
        view.keyboardType = keybordType
        return view
    }
    
    private func createErrorTextLabel() -> UILabel {
        let view = UILabel()
        view.numberOfLines = 0
        view.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        view.textColor = .red
        view.isHidden = true
        return view
    }
    
    private func createButton(title: String, color: UIColor, selector: Selector) -> UIButton {
        let view = UIButton()
        view.setTitle(title, for: .normal)
        view.backgroundColor = color
        view.layer.cornerRadius = 8
        view.addTarget(self, action: selector, for: .touchUpInside)
        view.heightAnchor.constraint(greaterThanOrEqualToConstant: 50).isActive = true
        return view
    }
}
