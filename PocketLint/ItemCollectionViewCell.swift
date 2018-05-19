//
//  ItemCollectionViewCell.swift
//  PocketLint
//
//  Created by Josiah Yeow on 27/4/18.
//  Copyright © 2018 Josiah Yeow. All rights reserved.
//

import UIKit
import Hero

protocol ItemCollectionViewCellDelegate: class {
    func showMenu(cell: ItemCollectionViewCell)
}

class ItemCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var menuButton: UIButton!
    
    weak var delegate: ItemCollectionViewCellDelegate?
    
    
    @IBAction func itemMenuTapped(_ sender: Any) {
        delegate?.showMenu(cell: self)
    }
    
}
