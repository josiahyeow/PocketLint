//
//  AddEditItemTableViewController.swift
//  PocketLint
//
//  Created by Josiah Yeow on 27/4/18.
//  Copyright © 2018 Josiah Yeow. All rights reserved.
//

import UIKit
import CoreData
import MapKit

class AddEditItemTableViewController: UITableViewController, CLLocationManagerDelegate {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var textContentTextField: UITextView!
    @IBOutlet weak var saveLocationToggle: UISwitch!
    
    // Managed Object Context and Initilisation Constructure for using Core Data.
    private var managedObjectContext: NSManagedObjectContext
    required init(coder aDecoder: NSCoder) {
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        managedObjectContext = (appDelegate?.persistentContainer.viewContext)!
        super.init(coder: aDecoder)!
    }
    
    var photo: UIImage?
    var item: Item?
    var newItem = true
    
    // Location variables
    var locationManager: CLLocationManager = CLLocationManager()
    var currentLocation: CLLocationCoordinate2D?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if ((photo) != nil) {
            self.title = "Add Item"
            // Set photo
            imageView.image = photo
        }
        else {
            self.title = "Edit Item"
            // Add item info
            imageView.image = UIImage(data:item?.image as! Data)
            titleTextField.text = item?.title
            textContentTextField.text = item?.textContent
            if (item?.longitude == 0 && item?.latitude == 0) {
                saveLocationToggle.isOn = false
            }
            newItem = false
        }
        // Set up location
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.distanceFilter = 10
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let loc: CLLocation = locations.last!
        currentLocation = loc.coordinate
    }
    
    @IBAction func cancelItem(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func saveItem(_ sender: Any) {
        
        if (newItem) {
            // Create new Item
            item = NSEntityDescription.insertNewObject(forEntityName: "Item", into: managedObjectContext) as? Item
            let imageData = UIImagePNGRepresentation(photo!) as NSData?
            item?.image = imageData
        }
        
        item?.title = titleTextField.text
        item?.date = Date()
        item?.textContent = textContentTextField.text
        
        if ((currentLocation) != nil && saveLocationToggle.isOn) {
            item?.latitude = Double(currentLocation!.latitude)
            item?.longitude = Double(currentLocation!.longitude)
        }
        else {
            item?.latitude = 0
            item?.longitude = 0
        }
        
        // Save item to Core Data
        do {
            try managedObjectContext.save()
            print("Photo was saved to Core Data")
            self.dismiss(animated: true, completion: nil)
        }
        catch let error {
            print("Could save Core Data: \(error)")
        }
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 4
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
