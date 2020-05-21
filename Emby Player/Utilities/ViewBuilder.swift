/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */
//
//  ViewBuilder.swift
//  Emby Player
//
//  Created by Mats Mollestad on 01/08/2019.
//  Copyright © 2019 Mats Mollestad. All rights reserved.
//

import UIKit

class ViewBuilder {

    static func scrollView(subview: UIView, keyboardDismissMode: UIScrollView.KeyboardDismissMode = .onDrag) -> UIScrollView {
        let view = UIScrollView()
        view.keyboardDismissMode = keyboardDismissMode
        view.addSubview(subview)
        view.alwaysBounceVertical = true
        subview.fillSuperView()
        subview.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 1).isActive = true
        return view
    }

    static func stackView(arrangedSubviews: [UIView], axis: NSLayoutConstraint.Axis = .vertical, spacing: CGFloat = 10, layoutMargins: UIEdgeInsets = .zero) -> UIStackView {
        let view = UIStackView(arrangedSubviews: arrangedSubviews)
        view.spacing = spacing
        view.axis = axis
        view.layoutMargins = layoutMargins
        view.isLayoutMarginsRelativeArrangement = true
        return view
    }

    static func textField(placeholder: String, text: String = "", keybordType: UIKeyboardType = .default, isSecureTextEntry: Bool = false, delegate: UITextFieldDelegate? = nil, returnKeyType: UIReturnKeyType = .done) -> UITextField {
        let view = VisibleTextField()
        view.placeholder = placeholder
        view.text = text
        view.borderStyle = .none
        view.keyboardType = keybordType
        view.isSecureTextEntry = isSecureTextEntry
        view.delegate = delegate
        let textColor = UIColor(white: 0.95, alpha: 1)
        view.textColor = textColor
        view.attributedPlaceholder = NSAttributedString(string: placeholder,
                                                        attributes: [NSAttributedString.Key.foregroundColor: textColor.withAlphaComponent(0.6)])
        view.returnKeyType = returnKeyType
        return view
    }

    static func textLabel(textColor: UIColor = .white, font: UIFont.TextStyle = .body, isHidden: Bool = false, text: String = "") -> UILabel {
        let view = UILabel()
        view.numberOfLines = 0
        view.font = UIFont.preferredFont(forTextStyle: font)
        view.textColor = textColor
        view.isHidden = isHidden
        view.text = text
        return view
    }

    static func button(title: String, color: UIColor, target: Any, selector: Selector) -> UIButton {
        let view = UIButton()
        view.setTitle(title, for: .normal)
        view.setTitleColor(.white, for: .normal)
        view.backgroundColor = color
        view.layer.cornerRadius = 8
        view.addTarget(target, action: selector, for: .touchUpInside)
        view.heightAnchor.constraint(greaterThanOrEqualToConstant: 50).isActive = true
        return view
    }

    static func picker(dataSource: UIPickerViewDataSource, delegate: UIPickerViewDelegate? = nil) -> UIPickerView {
        let view = UIPickerView()
        view.dataSource = dataSource
        view.delegate = delegate
        view.tintColor = .white
        return view
    }
}
