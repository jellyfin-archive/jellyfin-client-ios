/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */
//
//  UIViewExtension.swift
//  Reller
//
//  Created by Mats Moll on 12/31/16.
//  Copyright © 2016 Mats Moll. All rights reserved.
//

import UIKit

extension UIView {

    func centerVertical(in view: UIView, offset: CGFloat = 0) {
        translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: offset)
            ])
    }

    func centerHorizontal(in view: UIView, offset: CGFloat = 0) {
        translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: offset)
            ])
    }

    func centerInSuperview() {
        guard let superview = superview else { return }
        center(in: superview)
    }

    func center(in view: UIView, xOffset: CGFloat = 0, yOffset: CGFloat = 0) {
        translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: xOffset),
            centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: yOffset)
            ])
    }

    // The widht and height is Static
    func center(in view: UIView, equalToWidthConstant: CGFloat, equalToHeightConstant: CGFloat, xOffset: CGFloat = 0, yOffset: CGFloat = 0) {

        translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: xOffset),
            centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: yOffset),
            heightAnchor.constraint(equalToConstant: equalToHeightConstant),
            widthAnchor.constraint(equalToConstant: equalToWidthConstant)
            ])
    }

    // The widht and hight is relative to the defiend view
    func center(in view: UIView, relativeWidthConstant: CGFloat, relativeHeightConstant: CGFloat) {

        translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            centerXAnchor.constraint(equalTo: view.centerXAnchor),
            centerYAnchor.constraint(equalTo: view.centerYAnchor),
            heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 1, constant: relativeHeightConstant),
            widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 1, constant: relativeWidthConstant)
            ])
    }

    func fill(_ view: UIView) {
        anchorTo(top: view.topAnchor,
                 leading: view.leadingAnchor,
                 trailing: view.trailingAnchor,
                 bottom: view.bottomAnchor)
    }

    func fillSuperView(topConstant: CGFloat = 0, leadingConstant: CGFloat = 0, trailingConstant: CGFloat = 0, bottomConstant: CGFloat = 0) {

        guard let view = superview else {
            print("Auto Layout Error! \n\(self) is missing a superview")
            return
        }

        anchorWithConstantTo(top: view.topAnchor, topConstant: topConstant,
                             leading: view.leadingAnchor, leadingConstant: leadingConstant,
                             trailing: view.trailingAnchor, trailingConstant: trailingConstant,
                             bottom: view.bottomAnchor, bottomConstant: bottomConstant)
    }

    func fillSuperViewToSafeArea(topConstant: CGFloat = 0, leadingConstant: CGFloat = 0, trailingConstant: CGFloat = 0, bottomConstant: CGFloat = 0) {

        guard let view = superview else {
            print("Auto Layout Error! \n\(self) is missing a superview")
            return
        }

        if #available(iOS 11, *) {
            anchorWithConstantTo(top: view.safeAreaLayoutGuide.topAnchor, topConstant: topConstant,
                                 leading: view.safeAreaLayoutGuide.leadingAnchor, leadingConstant: leadingConstant,
                                 trailing: view.safeAreaLayoutGuide.trailingAnchor, trailingConstant: trailingConstant,
                                 bottom: view.safeAreaLayoutGuide.bottomAnchor, bottomConstant: bottomConstant)
        } else {
            fillSuperView(topConstant: topConstant, leadingConstant: leadingConstant, trailingConstant: trailingConstant, bottomConstant: bottomConstant)
        }
    }

    func setSize(height: CGFloat, width: CGFloat) {

        translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: width),
            heightAnchor.constraint(equalToConstant: height)
            ])
    }

    func setHeightAnchor(for value: CGFloat, withPriority: Float = 1000) {

        translatesAutoresizingMaskIntoConstraints = false

        let constraint = heightAnchor.constraint(equalToConstant: value)
        constraint.priority = UILayoutPriority(withPriority)

        NSLayoutConstraint.activate([constraint])
    }

    func setWidthAnchor(for value: CGFloat, withPriority: Float = 1000) {

        translatesAutoresizingMaskIntoConstraints = false

        let constraint = widthAnchor.constraint(equalToConstant: value)
        constraint.priority = UILayoutPriority(withPriority)

        NSLayoutConstraint.activate([constraint])
    }

    func anchorWithConstantTo(top: NSLayoutYAxisAnchor? = nil, topConstant: CGFloat = 0, leading: NSLayoutXAxisAnchor? = nil, leadingConstant: CGFloat = 0, trailing: NSLayoutXAxisAnchor? = nil, trailingConstant: CGFloat = 0, bottom: NSLayoutYAxisAnchor? = nil, bottomConstant: CGFloat = 0) {

        translatesAutoresizingMaskIntoConstraints = false

        if let top = top {
            topAnchor.constraint(equalTo: top, constant: topConstant).isActive = true
        }

        if let leading = leading {
            leadingAnchor.constraint(equalTo: leading, constant: leadingConstant).isActive = true
        }

        if let trailing = trailing {
            trailingAnchor.constraint(equalTo: trailing, constant: trailingConstant).isActive = true
        }

        if let bottom = bottom {
            bottomAnchor.constraint(equalTo: bottom, constant: bottomConstant).isActive = true
        }
    }

    func anchorTo(top: NSLayoutYAxisAnchor? = nil, leading: NSLayoutXAxisAnchor? = nil, trailing: NSLayoutXAxisAnchor? = nil, bottom: NSLayoutYAxisAnchor? = nil) {

        anchorWithConstantTo(top: top, leading: leading, trailing: trailing, bottom: bottom)
    }

    func aspectRatio(height: CGFloat, width: CGFloat) {
        widthAnchor.constraint(equalTo: heightAnchor, multiplier: height / width).isActive = true
    }
}
