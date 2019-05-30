//
//  LoginViewController.swift
//  Emby Player
//
//  Created by Mats Mollestad on 25/08/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//

import UIKit
import CryptoSwift

protocol LoginViewControllerDelegate: class {

    /// Presenting the home screen
    func loginWasSuccessfull(for user: User?)
}

class LoginViewController: UIViewController {

    /// The user to be authenticated
    let user: User?

    weak var delegate: LoginViewControllerDelegate?

    lazy var scrollView: UIScrollView       = self.setUpScrollView()
    lazy var contentStackView: UIStackView  = self.setUpContentStackView()
    lazy var errorTextView: UITextView      = self.setUpTextView()
    lazy var usernameTextField: UITextField = self.setUpUsernameField()
    lazy var imageView: UIImageView         = self.setUpImageView()
    lazy var passwordTextField: UITextField = self.setUpPasswordField()
    lazy var loginButton: UIButton          = self.setUpLoginButton()

    private var imageFetchTask: URLSessionTask?

    init(user: User? = nil) {
        self.user = user
        super.init(nibName: nil, bundle: nil)
        setUpViewController()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init?(coder aDecoder: NSCoder) Not implemented")
    }

    private func setUpViewController() {
        title = user?.name ?? "Login"
        view.backgroundColor = .black
        view.addSubview(scrollView)
        scrollView.fillSuperView()
        errorTextView.isHidden = true
        imageView.image = UIImage(named: "User Image")
        guard let user = user,
            let userImageUrl = ServerManager.currentServer?.baseUrl.appendingPathComponent("emby/Users/\(user.id)/Images/Primary") else {
                imageView.isHidden = true
                return
        }
        usernameTextField.isHidden = true
        imageFetchTask?.cancel()
        imageFetchTask = imageView.fetch(userImageUrl)
    }

    private func getUserLoginBody() -> AuthenticateUserByName? {

        guard let password = passwordTextField.text else { return nil }

        let username = user?.name ?? usernameTextField.text ?? ""

        let sha = password.sha1()
        let md5 = password.md5()

        return AuthenticateUserByName(username: username, passwordMd5: md5, password: sha, pw: password)
    }

    @objc
    func sendLoginRequest() {

        guard let requestBody = getUserLoginBody() else { return }

        usernameTextField.resignFirstResponder()
        passwordTextField.resignFirstResponder()

        ServerManager.currentServer?.autenticateUser(with: requestBody) { [weak self] (response) in
            DispatchQueue.main.async {
                switch response {
                case .success(let result):  self?.handleSuccess(with: result)
                case .failed(let error):
                    self?.errorTextView.text = "Error: " + error.localizedDescription
                    self?.errorTextView.isHidden = false
                }
            }
        }
    }

    private func handleSuccess(with result: AuthenticationResult) {
        UserManager.shared.login(with: result)
        delegate?.loginWasSuccessfull(for: user)
    }

    // MARK: - View Setup

    private func setUpScrollView() -> UIScrollView {
        let scrollView = UIScrollView()

        scrollView.alwaysBounceVertical = true
        scrollView.keyboardDismissMode = .onDrag

        scrollView.addSubview(contentStackView)
        contentStackView.fillSuperView()
        contentStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 1).isActive = true

        return scrollView
    }

    private func setUpContentStackView() -> UIStackView {
        let views = [errorTextView, imageView, usernameTextField, passwordTextField, loginButton]
        let stackView = UIStackView(arrangedSubviews: views)

        stackView.spacing = 20
        stackView.axis = .vertical
        stackView.layoutMargins = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        stackView.isLayoutMarginsRelativeArrangement = true

        if traitCollection.horizontalSizeClass == .regular {
            stackView.alignment = .center
        }

        return stackView
    }

    private func setUpTextView() -> UITextView {
        let view = UITextView()
        view.backgroundColor = .clear
        view.textColor = .red
        view.isScrollEnabled = false
        view.isEditable = false
        view.font = .boldSystemFont(ofSize: 20)
        return view
    }

    private func setUpImageView() -> UIImageView {
        let view = UIImageView()
        view.heightAnchor.constraint(equalTo: view.widthAnchor, multiplier: 1).isActive = true
        return view
    }

    private func setUpUsernameField() -> UITextField {
        let textField = UITextField()
        textField.borderStyle = .roundedRect
        textField.placeholder = "John Appleseed"
        return textField
    }

    private func setUpPasswordField() -> VisibleTextField {
        let textField = VisibleTextField()
        textField.isSecureTextEntry = true
        textField.borderStyle = .roundedRect
        textField.placeholder = "Password"
        textField.returnKeyType = .go
        textField.delegate = self
        return textField
    }

    private func setUpLoginButton() -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle("Login", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .orange
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(sendLoginRequest), for: .touchUpInside)
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return button
    }
}

extension LoginViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == usernameTextField {
            passwordTextField.becomeFirstResponder()
        } else {
            sendLoginRequest()
        }
        return false
    }
}
