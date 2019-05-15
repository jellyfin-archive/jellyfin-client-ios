//
//  EmbyLoginViewController.swift
//  Emby Player
//
//  Created by Mats Mollestad on 24/09/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//

import UIKit

struct LoginRequest: Codable {
    let username: String
    let password: String

    enum CodingKeys: String, CodingKey {
        case username = "nameOrEmail"
        case password = "rawpw"
    }
}

protocol EmbyLoginViewControllerDelegate: class {
    func connectToCustomServer()
    func willLogin(with request: LoginRequest)
}

class EmbyLoginViewController: UIViewController {

    private struct Strings {
        static let missingUsernameTitle = "Missing Username Input"
        static let missingPasswordTitle = "Missing Password Input"
        static let usernamePlaceholder = "example@email.com"
        static let passwordPlaceholder = "password"
        static let loginTitle = "Login"
        static let serverTitle = "Custom Server"
    }

    enum Errors: LocalizedError {
        case missingUsername
        case missingPassword

        public var errorDescription: String? {
            switch self {
            case .missingUsername: return Strings.missingUsernameTitle
            case .missingPassword: return Strings.missingPasswordTitle
            }
        }
    }

    lazy var scrollView: UIScrollView       = self.createScrollView()
    lazy var contentView: UIStackView       = self.createStackView()
    lazy var usernameTextField: UITextField = self.createTextField(placeholder: Strings.usernamePlaceholder, isSecure: false)
    lazy var passwordTextField: UITextField = self.createTextField(placeholder: Strings.passwordPlaceholder, isSecure: true)
    lazy var errorTextLabel: UILabel        = self.createErrorTextLabel()
    lazy var loginButton: UIButton          = self.createButton(title: Strings.loginTitle, color: .green, selector: #selector(self.loginButtonWasTapped))
    lazy var customServerButton: UIButton   = self.createButton(title: Strings.serverTitle, color: .orange, selector: #selector(self.customServerWasTapped))

    weak var delegate: EmbyLoginViewControllerDelegate?

    override func viewDidLoad() {
        setupViewController()
    }

    private func setupViewController() {
        title = "Emby Connect"
        view.backgroundColor = .white
        view.addSubview(scrollView)
        scrollView.fillSuperView()
    }

    private func getLoginRequest() throws -> LoginRequest {
        guard let username = usernameTextField.text, !username.isEmpty else { throw Errors.missingUsername }
        guard let password = passwordTextField.text, !password.isEmpty else { throw Errors.missingPassword }

        return LoginRequest(username: username, password: password)
    }

    func presentError(_ error: Error) {
        errorTextLabel.text = error.localizedDescription
        errorTextLabel.isHidden = false
    }

    @objc
    func loginButtonWasTapped() {
        do {
            let request = try getLoginRequest()
            delegate?.willLogin(with: request)
        } catch {
            presentError(error)
        }
    }

    @objc
    func customServerWasTapped() {
        delegate?.connectToCustomServer()
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
        let arrangedViews = [usernameTextField, passwordTextField, errorTextLabel, loginButton, customServerButton]
        let view = UIStackView(arrangedSubviews: arrangedViews)
        view.spacing = 10
        view.axis = .vertical
        view.layoutMargins = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        view.isLayoutMarginsRelativeArrangement = true
        return view
    }

    private func createTextField(placeholder: String, isSecure: Bool) -> UITextField {
        let view = VisibleTextField()
        view.placeholder = placeholder
        view.isSecureTextEntry = isSecure
        view.borderStyle = .roundedRect
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
