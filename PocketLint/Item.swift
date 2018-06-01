//
//  Item.swift
//  PocketLint
//
//  Created by Josiah Yeow on 11/5/18.
//  Copyright © 2018 Josiah Yeow. All rights reserved.
//
// This class is used to store Item attributes retrieved from Firebase

import UIKit

class Item: NSObject {
    var filename: String    // Name of the image file saved
    var imageURL: String    // URL of where the image is saved on Firebase
    var image: UIImage      // The actual image file
    var title: String       // A title describing the item
    var textContent: String // The text found in the image
    var date: Date          // The date of when the item was added
    var latitude: Double    // The latitude of where the item was added
    var longitude: Double   // The longitude of where the item was added
    
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
