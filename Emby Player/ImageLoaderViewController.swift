//
//  ImageLoaderViewController.swift
//  Emby Player
//
//  Created by Mats Mollestad on 29/08/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//

import UIKit


protocol ImageLoaderStoreFetchable {
    func fetchImage(in store: ImageLoaderStore, completion: @escaping (FetcherResponse<UIImage>) -> Void) -> URLSessionTask?
}

/// Fetches an image from an url with some emby server url parameters
struct ImageLoaderStoreEmbyFetcher: ImageLoaderStoreFetchable {
    
    enum Errors: Error {
        case invalidUrl
        case invalidImageData
    }
    
    let url: URL
    let maxSize: CGSize
    
    func fetchImage(in store: ImageLoaderStore, completion: @escaping (FetcherResponse<UIImage>) -> Void) -> URLSessionTask? {
        
        guard var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            completion(.failed(Errors.invalidUrl))
            return nil
        }
        
        urlComponents.queryItems = []
        if maxSize.width != 0 {
            urlComponents.queryItems?.append(URLQueryItem(name: "MaxWidth", value: "\(Int(maxSize.width))"))
        }
        if maxSize.height != 0 {
            urlComponents.queryItems?.append(URLQueryItem(name: "MaxHeight", value: "\(Int(maxSize.height))"))
        }
        
        guard let url = urlComponents.url else {
            completion(.failed(Errors.invalidUrl))
            return nil
        }
        
        print("ImageURL:", url)
        
        return NetworkRequester().getData(from: url) { (response) in
            switch response {
            case .success(let data):
                guard let image = UIImage(data: data) else {
                    completion(.failed(Errors.invalidImageData))
                    return
                }
//                AppCache.shared.set(image, key: url.absoluteString)
                completion(.success(image))
            case .failed(let error):
                completion(.failed(error))
            }
        }
    }
}

/// A fetcher that loades images from a cache
/// If there is no image, it transition to a server fetch
struct ImageLoaderStoreCacheFetcher: ImageLoaderStoreFetchable {
    
    let url: URL
    let maxSize: CGSize
    
    func fetchImage(in store: ImageLoaderStore, completion: @escaping (FetcherResponse<UIImage>) -> Void) -> URLSessionTask? {
        
        store.fetcherState = ImageLoaderStoreEmbyFetcher(url: url, maxSize: maxSize)
        return store.fetcherState.fetchImage(in: store, completion: completion)
    }
}


/// A class containing the image and delegateing the fetch
class ImageLoaderStore {
    
    /// The image to display
    var image: UIImage?
    
    /// The url task if it exists
    private var task: URLSessionTask?
    
    /// A state since it can switch from cache to http fetcher if needed
    var fetcherState: ImageLoaderStoreFetchable
    
    
    init(fetcherState: ImageLoaderStoreFetchable) {
        self.fetcherState = fetcherState
    }
    
    /// Fetches a image
    /// - parameter competion: A closure that will run when the item is feched
    /// - parameter response: A response object with an error or sucsess
    func fetchImage(completion: @escaping (_ response: FetcherResponse<Void>) -> Void) {
        clean()
        task = fetcherState.fetchImage(in: self) { [weak self] (response) in
            var retResponse: FetcherResponse<Void> = .success(())
            switch response {
            case .failed(let error): retResponse = .failed(error)
            case .success(let image): self?.image = image
            }
            self?.task = nil
            completion(retResponse)
        }
    }
    
    /// Deleating all data and canceling any active requests
    func clean() {
        image = nil
        task?.cancel()
    }
}


class ImageLoaderViewController: UIViewController {
    
    let store: ImageLoaderStore
    
    lazy var imageView: UIImageView = self.setUpImageView()
    
    var imageUrl: URL? {
        didSet {
            guard let url = imageUrl else { return }
            store.fetcherState = ImageLoaderStoreCacheFetcher(url: url, maxSize: imageView.bounds.size)
        }
    }
    
    
    init() {
        let placeholderImageUrl = URL(string: "https://uploads-ssl.webflow.com/57e5747bd0ac813956df4e96/5aebae14c6d254621d81f826_placeholder.png") ?? URL(fileURLWithPath: "")
        let cacheFetcher = ImageLoaderStoreCacheFetcher(url: placeholderImageUrl, maxSize: CGSize.zero)
        store = ImageLoaderStore(fetcherState: cacheFetcher)
        super.init(nibName: nil, bundle: nil)
        setUpViewController()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        store.clean()
    }
    
    func fetchContent() {
        self.imageView.alpha = 0
        store.fetchImage { (response) in
            DispatchQueue.main.async { [weak self] in
                self?.imageView.image = self?.store.image
                
                UIView.animate(withDuration: 0.4, animations: {
                    self?.imageView.alpha = 1
                })
            }
        }
    }
    
    private func setUpViewController() {
        view.backgroundColor = .clear
        view.addSubview(imageView)
        imageView.fillSuperView()
    }
    
    private func setUpImageView() -> UIImageView {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }
}
