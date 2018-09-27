//
//  ContentStateViewController.swift
//  Emby Player
//
//  Created by Mats Mollestad on 26/08/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//

import UIKit


protocol ContentViewControlling: class {
    func fetchContent(completion: @escaping (FetcherResponse<Void>) -> Void)
    var contentViewController: UIViewController { get }
}

class ContentStateViewController: UIViewController {
    
    enum State {
        case loading
        case failed(Error)
        case present
    }
    
    enum FetchMode {
        case onAppeare
        case onInit
        case none
    }
    
    
    private var state: State = .loading
    private var currentViewController: UIViewController?
    let contentController: ContentViewControlling
    var fetchMode: FetchMode
    
    var leftBarButton: UIBarButtonItem?
    var rightBarButton: UIBarButtonItem?
    
    init(contentController: ContentViewControlling, fetchMode: FetchMode, backgroundColor: UIColor = .clear) {
        self.contentController = contentController
        self.fetchMode = fetchMode
        super.init(nibName: nil, bundle: nil)
        view.backgroundColor = backgroundColor
        transition(to: .loading)
        
        let controller = contentController.contentViewController
        title = controller.title
        tabBarItem = controller.tabBarItem
        
        if fetchMode == .onInit {
            fetchContent()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if fetchMode == .onAppeare {
            fetchContent()
        }
    }
    
    func fetchContent() {
        contentController.fetchContent { [weak self] (response) in
            DispatchQueue.main.async {
                switch response {
                case .failed(let error):    self?.transition(to: .failed(error))
                case .success(_):           self?.transition(to: .present)
                }
            }
        }
    }
    
    func transition(to newState: State) {
        currentViewController?.remove()
        let newVC = viewController(for: newState)
        add(newVC)
        newVC.view.fillSuperView()
        currentViewController = newVC
        navigationItem.leftBarButtonItem = newVC.navigationItem.leftBarButtonItem ?? leftBarButton
        navigationItem.rightBarButtonItem = newVC.navigationItem.rightBarButtonItem ?? rightBarButton
        if #available(iOS 11, *) {
            navigationItem.searchController = newVC.navigationItem.searchController
        }
        state = newState
    }
    
    private func viewController(for state: State) -> UIViewController {
        switch state {
        case .loading:              return LoadingViewController()
        case .failed(let error):    return ErrorViewController(error: error, resolvHandler: fetchContent)
        case .present:              return contentController.contentViewController
        }
    }
}
