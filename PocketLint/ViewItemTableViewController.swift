//
//  ViewItemTableViewController.swift
//  PocketLint
//
//  Created by Josiah Yeow on 28/4/18.
//  Copyright © 2018 Josiah Yeow. All rights reserved.
//

import UIKit
import MapKit
import Firebase
import FirebaseDatabase
import FirebaseStorage

class ViewItemTableViewController: UITableViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var textContentTextView: UITextView!
    @IBOutlet weak var locationMapView: MKMapView!
    
    var item: Item?
    var itemDate: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.allowsSelection = false  // Turn off table cell highlighting
    
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // Update view with item content
        // Add image
        let image = UIImage(data:item?.image as! Data)
        imageView.image = image
        
        // Add Text
        self.title = item?.title
        titleLabel.text = item?.title
        textContentTextView.text = item?.textContent
        
        // Set date label
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm dd/MM/YYY"
        itemDate = formatter.string(from: (item?.date)!)
        dateLabel.text = itemDate
        
        // Show map if longitude and latitude was saved
        if(((item?.longitude) != 0) && ((item?.latitude) != 0)) {
            self.locationMapView.isHidden = false
            // Add pin to map
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: (item?.latitude)!, longitude: (item?.longitude)!)
            locationMapView.addAnnotation(annotation)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Menu action sheet
    
    @IBAction func menuTapped(_ sender: Any) {
        let alertController = UIAlertController(title: "Menu", message: nil, preferredStyle: .actionSheet)
        
        let editButton = UIAlertAction(title: "Edit", style: .default, handler: { (action) -> Void in
            self.performSegue(withIdentifier: "editItemSegue", sender: Any?.self)
        })
        
        let uploadButton = UIAlertAction(title: "Upload", style: .default, handler: { (action) -> Void in
            self.uploadItemToFirebase()
        })
        
        let  deleteButton = UIAlertAction(title: "Remove", style: .destructive, handler: { (action) -> Void in
            print("Delete button tapped")
        })
        
        let cancelButton = UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) -> Void in
            print("Cancel button tapped")
        })
        
        
        alertController.addAction(editButton)
        alertController.addAction(uploadButton)
        alertController.addAction(deleteButton)
        alertController.addAction(cancelButton)
        
        self.navigationController!.present(alertController, animated: true, completion: nil)
    }
    
    // MARK: - Upload item to Firebase
    
    private func uploadItemToFirebase() {
        let databaseRef = Database.database().reference().child("images")
        let storageRef = Storage.storage()
        
        guard let userID = Auth.auth().currentUser?.uid else {
            print("Firebase User ID is invalid.")
            return
        }
        
        let date = UInt(Date().timeIntervalSince1970)
        var data = Data()
        data = item?.image as! Data
        
        // Convert Core Data Entity into Dictionary
        let uploadItem: NSDictionary = [
            "title" : item?.title as! NSString,
            "textContent" : item?.textContent as! NSString,
            "latitude" : item?.latitude as! NSNumber,
            "longitude" : item?.longitude as! NSNumber
        ]
        
        let imageRef = storageRef.reference().child("\(userID)/\(date).jpg")
        
        // Set upload path
        let metaData = StorageMetadata()
        metaData.contentType = "image/jpg"
        imageRef.putData(data, metadata: metaData) {(metaData,error) in
            if let error = error {
                print(error.localizedDescription)
                self.displayMessage("Error", message: "Could not upload item.")
                return
            }
            else {
                // Upload item data
                databaseRef.child("users").child(userID).child("\(userID)/\(date)").setValue(uploadItem)
                
                // Store download URL of image
                let downloadURL = metaData!.downloadURL()!.absoluteString
                databaseRef.child("users").child(userID).child("\(userID)/\(date)").updateChildValues(["image": downloadURL])
                self.displayMessage("Success", message: "Photo uploaded!")

            }
        }
    }
    
    // Error Message Template
    
    func displayMessage(_ title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        
        alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default, handler: nil))
        
        self.present(alertController, animated: true, completion: nil)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 2
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


    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "editItemSegue" {
            if let destinationVC = segue.destination as? UINavigationController {
                // Pass the information of the book to the first View Controller connected to the Navigation Controller.
                let itemVC = destinationVC.viewControllers.first! as! AddEditItemTableViewController
                itemVC.item = item
            }
        }
    }


}
