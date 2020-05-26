/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */
//
//  ContentStateViewController.swift
//  Jellyfin Player
//
//  Created by Mats Mollestad on 26/08/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//

import UIKit

/// A protocol needed to use the ContentStateViewContoller
protocol ContentViewControlling: class {

    /// A methode to be called when loading data.
    /// Used to delegate the fetch
    ///
    /// - parameter completion: A closure to be when completed the fetch
    func fetchContent(completion: @escaping (FetcherResponse<Void>) -> Void)

    /// The view controller used to present the loaded data.
    var contentViewController: UIViewController { get }
}

/// Making it easier to use the protocol when the instance is of UIVewController
extension ContentViewControlling where Self: UIViewController {
    var contentViewController: UIViewController { return self }
}

/// A view controller simplifying loading content from a source
class ContentStateViewController: UIViewController {

    /// An enum for the different states
    enum State {

        /// Loading the content
        case loading

        /// An error occured
        case failed(Error)

        /// The content is presented
        case present
    }

    /// The different times to fetch the data
    enum FetchMode {

        /// Load when the view appeare
        case onAppeare

        /// Load on init
        case onLoad

        /// Define manualy when to load
        case none
    }

    /// The current state
    private var state: State = .loading

    /// The current controller to be displayed
    private lazy var currentViewController: UIViewController = self.viewController(for: self.state)

    /// The delegated responsebilities
    let contentController: ContentViewControlling

    /// The fetch mode
    var fetchMode: FetchMode

    /// Left bar button item if needed
    var leftBarButton: UIBarButtonItem?

    /// Right bar button item if needed
    var rightBarButton: UIBarButtonItem?

    init(contentController: ContentViewControlling, fetchMode: FetchMode, backgroundColor: UIColor = .clear) {
        self.contentController = contentController
        self.fetchMode = fetchMode
        super.init(nibName: nil, bundle: nil)
        view.backgroundColor = backgroundColor
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        transition(to: .loading)
        let controller  = contentController.contentViewController
        title           = controller.title
        tabBarItem      = controller.tabBarItem

        if fetchMode == .onLoad {
            fetchContent()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if fetchMode == .onAppeare {
            fetchContent()
        }
    }

    /// Start loading from the source
    func fetchContent() {
        contentController.fetchContent { [weak self] (response) in
            DispatchQueue.main.async {
                switch response {
                case .failed(let error):    self?.transition(to: .failed(error))
                case .success:           self?.transition(to: .present)
                }
            }
        }
    }

    /// Tranition to a state
    ///
    /// - parameter newState: The state to be presented
    private func transition(to newState: State) {
        state = newState
        currentViewController.remove()
        let newVC = viewController(for: newState)
        add(newVC)
        newVC.view.fillSuperView()
        currentViewController               = newVC
        navigationItem.leftBarButtonItem    = newVC.navigationItem.leftBarButtonItem    ?? leftBarButton
        navigationItem.rightBarButtonItem   = newVC.navigationItem.rightBarButtonItem   ?? rightBarButton
        if #available(iOS 11, *) {
            navigationItem.searchController = newVC.navigationItem.searchController
        }
    }

    /// A function returning the different view controllers to present in the differnet states
    ///
    /// - parameter state: The state to present
    private func viewController(for state: State) -> UIViewController {
        switch state {
        case .loading:              return LoadingViewController()
        case .failed(let error):    return ErrorViewController(error: error, resolvHandler: fetchContent)
        case .present:              return contentController.contentViewController
        }
    }
}
