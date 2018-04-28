//
//  LocationAnnotation.swift
//  PocketLint
//
//  Created by Josiah Yeow on 28/4/18.
//  Copyright © 2018 Josiah Yeow. All rights reserved.
//

import Foundation
import MapKit

class LocationAnnotation: NSObject, MKAnnotation{
    
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    
    @objc init( newTitle: String, newSubtitle: String, lat: Double, long: Double){
        title = newTitle
        subtitle = newSubtitle
        coordinate = CLLocationCoordinate2D()
        coordinate.latitude = lat
        coordinate.longitude = long
    }
    
    
    
}
