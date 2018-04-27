//
//  ViewItemViewController.swift
//  PocketLint
//
//  Created by Josiah Yeow on 27/4/18.
//  Copyright © 2018 Josiah Yeow. All rights reserved.
//

import UIKit
import MapKit

class ViewItemViewController: UIViewController {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var textContentTextView: UITextView!
    @IBOutlet weak var locationMapView: MKMapView!
    
    var item: Item?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Update view with item content
        //imageView.image = image
        
        titleLabel.text = item?.title
        textContentTextView.text = item?.textContent
        
        // Set date label
        //let formatter = DateFormatter()
        //formatter.dateFormat = "HH:mm a DD,MM,YYYY"
        //let date = formatter.string(from: (item?.date)!)
        //dateLabel.text = date
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
