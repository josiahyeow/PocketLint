//
//  Item.swift
//  PocketLint
//
//  Created by Josiah Yeow on 11/5/18.
//  Copyright © 2018 Josiah Yeow. All rights reserved.
//

import UIKit

class Item: NSObject {
    var filename: String
    var imageURL: String
    var image: UIImage
    var title: String
    var textContent: String
    var date: Date
    var latitude: Double
    var longitude: Double
    
    override init() {
        filename = ""
        imageURL = ""
        image = UIImage()
        title = ""
        textContent = ""
        date = Date()
        latitude = 0
        longitude = 0
    }
    
    init(filename: String, imageURL: String, image: UIImage, title: String, textContent: String, date: Date, latitude: Double, longitude: Double) {
        self.filename = filename
        self.imageURL = imageURL
        self.image = image
        self.title = title
        self.textContent = textContent
        self.date = date
        self.latitude = latitude
        self.longitude = longitude
    }
}
