//
//  AddEditItemTableViewController.swift
//  PocketLint
//
//  Created by Josiah Yeow on 27/4/18.
//  Copyright © 2018 Josiah Yeow. All rights reserved.
//

import UIKit
import MapKit
import Firebase

protocol AddEditItemTableViewControllerDelegate: class {
    func updateItem(title: String, textContent: String)
}

class AddEditItemTableViewController: UITableViewController, CLLocationManagerDelegate {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var textContentTextField: UITextView!
    @IBOutlet weak var saveLocationToggle: UISwitch!
    @IBOutlet weak var uploadProgressView: UIProgressView!
    @IBOutlet weak var detectLabelActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var detectTextActivityIndicator: UIActivityIndicatorView!
    
    let defaults = UserDefaults.standard
    
    weak var delegate: AddEditItemTableViewControllerDelegate?
    
    // Firebase database and storage variables
    var databaseRef = Database.database().reference().child("users")
    var storageRef = Storage.storage().reference().child("users")
    
    // Text recognition variables
    lazy var vision = Vision.vision()
    
    var photo: UIImage?
    var item: Item?
    var newItem = true
    
    // Location variables
    var locationManager: CLLocationManager = CLLocationManager()
    var currentLocation: CLLocationCoordinate2D?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.allowsSelection = false
        
        guard let userID = Auth.auth().currentUser?.uid else {
            print("Firebase User ID is invalid.")
            return
        }
        // Store items in user's account folder
        databaseRef = Database.database().reference().child("users").child("\(userID)")
        storageRef = Storage.storage().reference().child("users").child("\(userID)")
        
        if ((photo) != nil) {
            self.title = "Add Item"
            // Set photo
            imageView.image = photo
        }
        else {
            self.title = "Edit Item"
            // Add item info
            imageView.image = item?.image
            titleTextField.text = item?.title
            textContentTextField.text = item?.textContent
            
            if (item?.longitude == 0 && item?.latitude == 0) {
                saveLocationToggle.isOn = false
            }
            newItem = false
        }
        textContentTextField.delegate = self
        // Set up location
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.distanceFilter = 10
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        // Get text detection value
        if defaults.object(forKey: "textDetection") as! Bool {
            // Scan photo
            if (newItem) {
                self.detectLabel()
                self.detectText()
            }
        }
        
        // Get save location value
        if defaults.object(forKey: "saveLocation") as! Bool {
            saveLocationToggle.isOn = true
        }
        else {
            saveLocationToggle.isOn = false
        }
        
        self.uploadProgressView.setProgress(0, animated: false)

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let loc: CLLocation = locations.last!
        currentLocation = loc.coordinate
    }
    
    // MARK: MLKit Text Detection Functions
    
    func detectLabel() {
        let labelDetector = vision.cloudLabelDetector()  // Check console for errors.
        let image = VisionImage(image: imageView.image!)
        
        // Start activity indicator
        self.detectLabelActivityIndicator.startAnimating()
        
        labelDetector.detect(in: image) { (labels: [VisionCloudLabel]?, error: Error?) in
            guard error == nil, let labels = labels, !labels.isEmpty else {
                let errorString = error?.localizedDescription
                print("Item detection failed with error: \(String(describing: errorString))")
                self.detectLabelActivityIndicator.stopAnimating()
                return
            }
            
            for label in labels {
                self.titleTextField.text = label.label
                self.detectLabelActivityIndicator.stopAnimating()
            }
        }
    }
    
    func detectText() {
        let textDetector = vision.cloudTextDetector()  // Check console for errors.
        let image = VisionImage(image: imageView.image!)
        
        // Start activity indicator
        self.detectTextActivityIndicator.startAnimating()
        
        textDetector.detect(in: image) { (cloudText, error) in
            guard error == nil, let cloudText = cloudText else {
                let errorString = error?.localizedDescription
                print("Text detection failed with error: \(String(describing: errorString))")
                self.detectTextActivityIndicator.stopAnimating()
                return
            }
            
            // Recognized and extracted text
            self.textContentTextField.text = cloudText.text
            self.detectTextActivityIndicator.stopAnimating()
            
        }
    }
    
    // MARK: Actions
    
    @IBAction func cancelItem(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func saveItem(_ sender: Any) {
        if(newItem) {
            addItemToFirebase()
        }
        else {
            editItemOnFirebase()
        }
        
    }
    
    // Converts Date object to String
    private func dateToString(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss zzz"
        let date = formatter.string(from: (date))
        return date
    }
    
    // MARK: Firebase Activities
    
    private func addItemToFirebase() {
        let filename = UInt(Date().timeIntervalSince1970)
        let image = UIImageJPEGRepresentation(imageView.image!, 0.8)!
        let date = self.dateToString(date: Date())
        let title = titleTextField.text
        let textContent = textContentTextField.text
        var latitude = 0 as Double
        var longitude = 0 as Double
        
        // Get user's location (if turned on)
        if ((currentLocation) != nil && saveLocationToggle.isOn) {
            latitude = Double(currentLocation!.latitude)
            longitude = Double(currentLocation!.longitude)
        }
        
        // Convert Core Data Entity into Dictionary for upload
        let uploadItem: NSDictionary = [
            "date": date as NSString,
            "title" : title as NSString? ?? "",
            "textContent" : textContent as NSString? ?? "",
            "latitude" : latitude as NSNumber? ?? 0,
            "longitude" : longitude as NSNumber? ?? 0
        ]
        
        
        let imageRef = self.storageRef.child("\(filename).jpg")
        var downloadURL: String!
        
        // Set upload path
        let metaData = StorageMetadata()
        metaData.contentType = "image/jpg"
        let uploadTask = imageRef.putData(image, metadata: metaData) {(metaData,error) in
            if let error = error {
                print(error.localizedDescription)
                self.displayMessage("Error", message: "Could not upload item.")
                return
            }
            else {
                // Upload item data
                self.databaseRef.child("\(filename)").setValue(uploadItem)
                
                // Store download URL of image
                imageRef.downloadURL(completion: { url, error in
                    if let error = error {
                        print(error.localizedDescription)
                    } else {
                        downloadURL = url!.absoluteString
                        self.databaseRef.child("\(filename)").setValue(uploadItem)
                        self.databaseRef.child("\(filename)").updateChildValues(["image": downloadURL])
                        self.dismiss(animated: true, completion: nil)
                        //self.displayMessage("Success", message: "Photo uploaded!")
                        
                    }
                })
            }
        }
        
        // Update upload progress view
        uploadTask.observe(.progress) { snapshot in
            let percentComplete = 100.0 * Double(snapshot.progress!.completedUnitCount) /  Double(snapshot.progress!.totalUnitCount)
            print(percentComplete)
            self.uploadProgressView.setProgress(Float(percentComplete), animated: true)
        }
    }
    
    private func editItemOnFirebase() {
        let filename = item?.filename
        let title = titleTextField.text
        let textContent = textContentTextField.text
        
        // Update item in database
        self.databaseRef.child("\(filename!)").updateChildValues(["title": title ?? "", "textContent": textContent ?? ""])
        self.delegate?.updateItem(title: title!, textContent: textContent!)
        self.dismiss(animated: true, completion: nil)
    }
    
    // Error Message Template
    
    func displayMessage(_ title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        
        alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default, handler: nil))
        
        self.present(alertController, animated: true, completion: nil)

    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // Only show save location toggle if adding new item
        if newItem {
            return 4
        }
        else {
            return 3
        }
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

extension AddEditItemTableViewController: UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        let size = CGSize(width: textView.frame.size.width, height: .infinity)
        let estimatedSize = textView.sizeThatFits(size)
        
        textView.constraints.forEach { (constraint) in
            if constraint.firstAttribute == .height {
                constraint.constant = estimatedSize.height
            }
        }

    }
}
