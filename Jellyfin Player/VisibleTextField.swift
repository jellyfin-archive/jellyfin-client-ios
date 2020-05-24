/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */
//
//  VisableTextField.swift
//  Solpumpa iOS
//
//  Created by Mats Mollestad on 19/06/2017.
//  Copyright © 2017 Inforte. All rights reserved.
//

import UIKit


class VisibleTextField: UITextField {
    
    
    /// The distance form the keyboard to the selected text field in points
    var textFieldKeyboardDistance: CGFloat = 20
    
    
    
    /// Is used to move the content offset so the text fields wont be hidden form the user
    private var keyboardHeight: CGFloat = 0
    
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        registerObservers()
    }
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        registerObservers()
    }
    

    
    var willShowNotification: NSObjectProtocol?
    var didBeginEditingNotification: NSObjectProtocol?
    var willHideNotification: NSObjectProtocol?
    var didEndEditingNotification: NSObjectProtocol?
    
    
    /// Regestrates the view for all the needed observers
    func registerObservers() {
        
        DispatchQueue.global().async { [weak self] in      // Running on the background thread so the first is also running in the background
            
            let center = NotificationCenter.default
            
            self?.willShowNotification = center.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: nil, using: { (notification: Notification) in
                
                if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
                    self?.keyboardHeight = keyboardSize.height
                    
                    if self?.isFirstResponder == true {
                        DispatchQueue.main.async {
                            self?.keyboard(is: true)
                        }
                    }
                }
            })
            
            self?.didBeginEditingNotification = center.addObserver(forName: UITextField.textDidBeginEditingNotification, object: self, queue: OperationQueue.main) { (_) in
                
                self?.keyboard(is: true)
                // When the textView is beginning editing, add an observer for the keyboard
                
                self?.willHideNotification = NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: self, queue: OperationQueue.main) { (notification) in
                    
                    self?.keyboard(is: false)
                }
            }
            
            self?.didEndEditingNotification = center.addObserver(forName: UITextField.textDidEndEditingNotification, object: self, queue: OperationQueue.main) { (_) in
                
                // When the textView is beginning editing, remove the observer for the keyboard
                if let notification = self?.willHideNotification {
                    NotificationCenter.default.removeObserver(notification)
                }
            }
        }
    }
    
    
    /// Removes all the observers when deinited
    deinit {
        NotificationCenter.default.removeObserver(willShowNotification!)
        NotificationCenter.default.removeObserver(didBeginEditingNotification!)
        NotificationCenter.default.removeObserver(didEndEditingNotification!)
    }
    
    
    
    /**
     This function changes the content offset, so the text field wont be hidden form the user.
     
     - parameter shown: Bool type to indicate if the keyboard is shown or dismissed
     - parameter view: The view which is supposed to be visible
     */
    fileprivate func keyboard(is shown: Bool) {
        
        // Finding the scrollView to change the contentOffset of and the superviews which the text field is inbedded in
        var superviews: [UIView] = [self]
        
        
        var currentSuperView: UIView = self

        while !(currentSuperView.superview is UIScrollView) {
            guard let superview = currentSuperView.superview else { return }
            
            superviews.append(superview)
            
            currentSuperView = superview
        }
        
        guard let scrollView = currentSuperView.superview as? UIScrollView else {
            return
        }
        
        
        /// Checking which animation to do
        
        var animation: () -> Void = {}
        
        if !shown && scrollView.contentOffset.y > scrollView.contentSize.height {
            animation = { scrollView.contentOffset.y = scrollView.contentSize.height }
        } else if shown {
            
            let textFieldYCordinate = superviews.reduce(0) { $0 + $1.frame.origin.y } + self.frame.height + textFieldKeyboardDistance
            
            let keyboardYCordinate = scrollView.contentOffset.y + scrollView.frame.height - keyboardHeight
            
            if textFieldYCordinate > keyboardYCordinate {
                let differance = keyboardYCordinate - textFieldYCordinate
                
                animation = { scrollView.contentOffset.y -= differance }
            }
        }
        
        UIView.animate(withDuration: 0.2, animations: animation)
    }
}
