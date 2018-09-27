//
//  ImageLoaderViewController.swift
//  Emby Player
//
//  Created by Mats Mollestad on 29/08/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//

import UIKit


class AppCache {
    static let shared = AppCache()
    
    let imageCache = NSCache<NSString, UIImage>()
    
    func imageFor(key: String) -> UIImage? {
        return imageCache.object(forKey: NSString(string: key))
    }
    
    func set(_ image: UIImage, key: String) {
        imageCache.setObject(image, forKey: NSString(string: key))
    }
}


protocol ImageLoaderStoreFetchable {
    func fetchImage(in store: ImageLoaderStore, completion: @escaping (FetcherResponse<UIImage>) -> Void) -> URLSessionTask?
}


struct ImageLoaderStoreEmbyFetcher: ImageLoaderStoreFetchable {
    let url: URL
    let maxSize: CGSize
    
    func fetchImage(in store: ImageLoaderStore, completion: @escaping (FetcherResponse<UIImage>) -> Void) -> URLSessionTask? {
        
        guard var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            completion(.failed(NSError(domain: "ImageLoaderStoreEmbyFetcher", code: 0, userInfo: nil)))
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
            completion(.failed(NSError(domain: "ImageLoaderStoreEmbyFetcher", code: 0, userInfo: nil)))
            return nil
        }
        
        print("ImageURL:", url)
        
        return NetworkRequester().getData(from: url) { (response) in
            switch response {
            case .success(let data):
                guard let image = UIImage(data: data) else {
                    completion(.failed(NSError(domain: "ImageLoaderStoreEmbyFetcher", code: 0, userInfo: nil)))
                    return
                }
                AppCache.shared.set(image, key: url.absoluteString)
                completion(.success(image))
            case .failed(let error):
                completion(.failed(error))
            }
        }
    }
}

struct ImageLoaderStoreCacheFetcher: ImageLoaderStoreFetchable {
    
    let url: URL
    let maxSize: CGSize
    
    func fetchImage(in store: ImageLoaderStore, completion: @escaping (FetcherResponse<UIImage>) -> Void) -> URLSessionTask? {
        
        if let image = AppCache.shared.imageFor(key: url.absoluteString) {
            completion(.success(image))
        } else {
            store.fetcherState = ImageLoaderStoreEmbyFetcher(url: url, maxSize: maxSize)
            return store.fetcherState.fetchImage(in: store, completion: completion)
        }
        return nil
    }
}


class ImageLoaderStore {
    
    var image: UIImage?
    private var task: URLSessionTask?
    
    /// A state since it can switch from cache to http fetcher if needed
    var fetcherState: ImageLoaderStoreFetchable
    
    init(fetcherState: ImageLoaderStoreFetchable) {
        self.fetcherState = fetcherState
    }
    
    func fetchImage(completion: @escaping (FetcherResponse<Void>) -> Void) {
        task = fetcherState.fetchImage(in: self) { [weak self] (response) in
            var retResponse: FetcherResponse<Void> = .success(())
            switch response {
            case .failed(let error): retResponse = .failed(error)
            case .success(let image): self?.image = image
            }
            completion(retResponse)
            self?.task = nil
        }
    }
    
    func clean() {
        task?.cancel()
    }
}


class ImageLoaderViewController: UIViewController, ContentViewControlling {
    
    let store: ImageLoaderStore
    
    lazy var imageView: UIImageView = self.setUpImageView()
    
    var contentViewController: UIViewController { return self }
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
    
    func fetchContent(completion: @escaping (FetcherResponse<Void>) -> Void) {
        store.fetchImage { (response) in
            completion(response)
            DispatchQueue.main.async {
                self.imageView.image = self.store.image
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
