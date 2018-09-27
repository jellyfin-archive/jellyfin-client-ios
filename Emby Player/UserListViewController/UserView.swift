//
//  UserView.swift
//  Emby Player
//
//  Created by Mats Mollestad on 22/09/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//

import UIKit

class ImageSubtitleView: UIView {
    
    lazy var imageView: UIImageView = self.createImageView()
    lazy var titleLabel: UILabel = UILabel()
    
    var imageCornerRadius: CGFloat {
        get { return imageView.layer.cornerRadius }
        set { imageView.layer.cornerRadius = newValue }
    }
    
    init() {
        super.init(frame: .zero)
        setUpView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUpView()
    }
    
    private func setUpView() {
        backgroundColor = .clear
        addSubview(imageView)
        addSubview(titleLabel)
        
        imageView.anchorTo(top: topAnchor,
                           leading: leadingAnchor,
                           trailing: trailingAnchor)
        titleLabel.anchorWithConstantTo(top: imageView.bottomAnchor, topConstant: 10,
                                        leading: leadingAnchor,
                                        trailing: trailingAnchor,
                                        bottom: bottomAnchor)
    }
    
    private func createImageView() -> UIImageView {
        let view = UIImageView()
        view.heightAnchor.constraint(equalTo: view.widthAnchor, multiplier: 1).isActive = true
        return view
    }
}

class UserCollectionViewCell: UICollectionViewCell {
    
    private let infoView = ImageSubtitleView()
    
    var imageView: UIImageView { return infoView.imageView }
    var titleLabel: UILabel { return infoView.titleLabel }
    
    var imageCornerRadius: CGFloat {
        get { return infoView.imageCornerRadius }
        set { infoView.imageCornerRadius = newValue }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUpView()
    }
    
    private func setUpView() {
        addSubview(infoView)
        infoView.fillSuperView()
        
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
    }
}
