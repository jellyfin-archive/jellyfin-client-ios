//
//  CatagoryTableViewCell.swift
//  Emby Player
//
//  Created by Mats Mollestad on 27/08/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//

import UIKit


class MediaFolderTableViewCell: UITableViewCell {
    
    var catagoryController: HorizontalCatagoryLatestLibraryViewController?
    var controller: ContentStateViewController?
    
    var catagory: MediaFolder? {
        didSet {
            updateForCatagory()
        }
    }
    
    lazy var titleLabel: UILabel = self.setUpTitleLabel()
    lazy var contentStackView: UIStackView = self.setUpContentStackView()
    
    var superViewController: UIViewController?
    weak var delegate: HorizontalCatagoryLibraryViewControllerDelegate? {
        didSet {
            catagoryController?.delegate = delegate
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setUpCell()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUpCell()
    }
    
    private func updateForCatagory() {
        
        guard let catagory = catagory else { return }
        guard let superViewController = superViewController else { return }
        
        titleLabel.text = catagory.name
        
        controller?.willMove(toParent: nil)
        controller?.view.removeFromSuperview()
        controller?.removeFromParent()
        catagoryController = HorizontalCatagoryLatestLibraryViewController(catagory: catagory)
        catagoryController?.delegate = delegate
        controller = ContentStateViewController(contentController: catagoryController!, fetchMode: .onInit)
        
        guard let subView = controller?.view else { return }
        subView.heightAnchor.constraint(equalToConstant: 200).isActive = true
        contentStackView.removeArrangedSubview(subView)
        contentStackView.addArrangedSubview(subView)
        superViewController.addChild(controller!)
        controller?.didMove(toParent: superViewController)
    }
    
    
    private func setUpCell() {
        addSubview(contentStackView)
        contentStackView.fillSuperView()
        selectionStyle = .none
    }
    
    private func setUpTitleLabel() -> UILabel {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        label.textColor = .white
        return label
    }
    
    private func setUpContentStackView() -> UIStackView {
        let view = UIStackView(arrangedSubviews: [titleLabel])
        view.axis = .vertical
        view.spacing = 20
        view.layoutMargins = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
        view.isLayoutMarginsRelativeArrangement = true
        return view
    }
}
