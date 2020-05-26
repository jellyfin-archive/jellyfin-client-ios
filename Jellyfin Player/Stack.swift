/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */
//
//  Stack.swift
//  Jellyfin Player
//
//  Created by Mats Mollestad on 12/09/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//

import Foundation

/// A object containing a value in a linked list
/// Using class to use referances in stead of coping all the elements each time the list changes
class LinkedObject<T> {
    let value: T
    var next: LinkedObject<T>?

    init(value: T) {
        self.value = value
    }
}

struct Stack<T> {

    private var object: LinkedObject<T>?

    init() {}

    init(values: [T]) {
        for value in values {
            add(value)
        }
    }

    mutating func add(_ newValue: T) {
        let newObject = LinkedObject(value: newValue)
        newObject.next = object
        object = newObject
    }

    mutating func pop() -> T? {
        let popedValue = object?.value
        object = object?.next
        return popedValue
    }

    func peek() -> T? {
        return object?.value
    }

    var isEmpty: Bool {
        return object == nil
    }

    var count: Int {
        guard var current = object else { return 0 }
        var count = 1
        while current.next != nil {
            count += 1
            current = current.next!
        }
        return count
    }
}
