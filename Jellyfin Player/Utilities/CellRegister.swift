/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */
//
//  CellRegister.swift
//
//  Created by Mats Mollestad on 28/01/2017.
//  Copyright © 2017 Mats Moll. All rights reserved.
//

import UIKit

extension UICollectionView {

    /**
     Registrates a UICollectionViewCell in a UICollectionView with a reuseIdentifier same as the cell class name
     
     - parameter cellType: The cell class to registrate
     */
    func register<Cell: UICollectionViewCell>(_ cellType: Cell.Type) {
        self.register(cellType, forCellWithReuseIdentifier: "\(cellType)")
    }

    /**
     Registrates a UICollectionViewCell with a xib file in a UICollectionView with a reuseIdentifier same as the cell class name
     
     - parameter cellType: The cell class to registrate
     */
    func registerNib<Cell: UICollectionViewCell>(_ cellType: Cell.Type) {
        let nib = UINib(nibName: "\(cellType)", bundle: nil)
        register(nib, forCellWithReuseIdentifier: "\(cellType)")
    }

    /**
     Registrates a UICollectionViewCell in a UICollectionView with a reuseIdentifier same ass the cell class name
     
     - parameter cellType: The cell class to registrate
     - parameter forSupplementryViewOfKind: The type of view (UICollectionViewViewKind)
     */
    func register<Cell: UICollectionReusableView>(_ cellType: Cell.Type, forSupplementryViewOfKind: String) {
        self.register(cellType, forSupplementaryViewOfKind: forSupplementryViewOfKind, withReuseIdentifier: "\(cellType)")
    }

    /**
     Registrates a UICollectionViewCell with a xib file in a UICollectionView with a reuseIdentifier same ass the cell class name
     
     - parameter cellType: The cell class to registrate
     - parameter forSupplementryViewOfKind: The type of view (UICollectionViewViewKind)
     */
    func registerNib<Cell: UICollectionViewCell>(_ cellType: Cell.Type, forSupplementryViewOfKind: String) {
        let nib = UINib(nibName: "\(cellType)", bundle: nil)
        self.register(nib, forSupplementaryViewOfKind: forSupplementryViewOfKind, withReuseIdentifier: "\(cellType)")
    }

    /**
     Dequeue a reusable UICollectionViewCell in a UICollectionView with a reuseIdentifier same ass the cell class name
     
     - parameter indexPath: The IndexPath of the cell to show
     - parameter type: The cell class to return
     
     - returns: A UICollectionViewCell of the type class
     */
    func cellForItem<Cell: UICollectionViewCell>(at indexPath: IndexPath, ofType type: Cell.Type) -> Cell {
        return self.dequeueReusableCell(withReuseIdentifier: "\(type)", for: indexPath) as! Cell
    }

    /**
     Dequeue a reusable UICollectionViewCell in a UICollectionView with a reuseIdentifier same ass the cell class name
     
     - parameter kind: The type of view (UICollectionViewViewKind)
     - parameter indexPath: The IndexPath of the cell to show
     - parameter type: The cell class to return
     
     - returns: A UICollectionViewCell of the cellType class
     */
    func supplementaryView<Cell: UICollectionReusableView>(ofKind kind: String, for indexPath: IndexPath, ofType type: Cell.Type) -> Cell {
        return self.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "\(type)", for: indexPath) as! Cell
    }
}

extension UITableView {

    /**
     Registrates a UITableViewCell in a UITableView with a reuseIdentifier same as the cell class name
     
     - parameter cellType: The cell class to registrate
     */
    func register<Cell: UITableViewCell>(_ cellType: Cell.Type) {
        self.register(cellType, forCellReuseIdentifier: "\(cellType)")
    }

    /**
     Registrates a UITableViewCell with a xib file in a UITableView with a reuseIdentifier same as the cell class name
     
     - parameter cellType: The cell class to registrate
     */
    func registerNib<Cell: UITableViewCell>(_ cellType: Cell.Type) {
        let nib = UINib(nibName: "\(cellType)", bundle: nil)
        register(nib, forCellReuseIdentifier: "\(cellType)")
    }
    /**
     Registrates a UITableViewCell hedder or footer in a UITableView with a reuseIdentifier same as the cell class name
     
     - parameter cellType: The cell class to registrate
     */
    func registerHeaderOrFooter<Cell: UITableViewCell>(ofType cellType: Cell.Type) {
        self.register(cellType, forHeaderFooterViewReuseIdentifier: "\(cellType)")
    }

    /**
     Dequeue a reusable UITableViewCell in a UITableView with a reuseIdentifier same ass the cell class name
     
     - parameter indexPath: The IndexPath of the cell to show
     - parameter type: The cell class to return
     
     - returns: A UITableViewCell of the type class
     */
    func cellForItem<Cell: UITableViewCell>(at indexPath: IndexPath, ofType type: Cell.Type) -> Cell {
        return self.dequeueReusableCell(withIdentifier: "\(type)", for: indexPath) as! Cell
    }

    /**
     Dequeue a reusable UITableViewCell in a UITableView with a reuseIdentifier same ass the cell class name
     
     - parameter indexPath: The IndexPath of the cell to show
     
     - returns: A UITableViewCell of the type class
     */
    func cellForItem<Cell: UITableViewCell>(at indexPath: IndexPath) -> Cell {
        return self.dequeueReusableCell(withIdentifier: "\(Cell.self)", for: indexPath) as! Cell
    }

    /**
     Dequeue a reusable UITableViewCell header or footer in a UITableView with a reuseIdentifier same ass the cell class name
     
     - parameter type: The cell class to return
     
     - returns: A UITableViewCell of the type class
     */
    func headerOrFooter<Cell: UITableViewHeaderFooterView>(ofType type: Cell.Type) -> Cell {
        return self.dequeueReusableHeaderFooterView(withIdentifier: "\(type)") as! Cell
    }
}
