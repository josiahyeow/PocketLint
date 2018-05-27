//
//  AddEditItemTableViewController.swift
//  PocketLint
//
//  Created by Josiah Yeow on 27/4/18.
//  Copyright © 2018 Josiah Yeow. All rights reserved.
//
// This TableViewController allows the user to add or edit an item.
// It allows the user edit an item's title and textContent or
// to use Google's MLKit to detect the image's content as well as save the location the image was taken.

import UIKit
import MapKit
import Firebase

// This tell's the ViewItemTableView to refresh its views.
protocol AddEditItemTableViewControllerDelegate: class {
    func update()
}

class AddEditItemTableViewController: UITableViewController, CLLocationManagerDelegate {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var textContentTextField: UITextView!
    @IBOutlet weak var saveLocationToggle: UISwitch!
    @IBOutlet weak var uploadProgressView: UIProgressView!
    @IBOutlet weak var detectLabelActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var detectTextActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var detectTextButton: UIButton!
    @IBOutlet weak var detectItemButton: UIButton!
    
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
        
        // Get Firebase User ID
        guard let userID = Auth.auth().currentUser?.uid else {
            print("Firebase User ID is invalid.")
            return
        }
        
        // Set database and storage paths to the user's account folder
        databaseRef = Database.database().reference().child("users").child("\(userID)")
        storageRef = Storage.storage().reference().child("users").child("\(userID)")
        
        // Set up form based on Adding or Editing an item.
        addOrEdit()
        
        // Set up location
        setUpLocationManager()
        
        // Autodetect text and save location if setting is turned on.
        applySettings()
        
        // Initialise upload progress view to 0.
        self.uploadProgressView.setProgress(0, animated: false)

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Data Initialisation Functions
    
    // Add data based on whether an item is being added or edited.
    func addOrEdit() {
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
    }
    
    // Set up location manager properties
    func setUpLocationManager() {
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.distanceFilter = 10
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let loc: CLLocation = locations.last!
        currentLocation = loc.coordinate
    }
    
    // Apply user settings. Auto detect text if setting is turned on.
    func applySettings() {
        // Get title detection value
        if defaults.object(forKey: "itemDetection") as! Bool {
            // Scan photo
            if (newItem) {
                self.detectLabel()
            }
        }
        // Get text detection value
        if defaults.object(forKey: "textDetection") as! Bool {
            // Scan photo
            if (newItem) {
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
    }
    
    // MARK: MLKit Text Detection Functions
    
    /*
     Detect objects in image and apply it to the item's title.
     
     References: https://firebase.google.com/docs/ml-kit/ios/label-images
    */
    func detectLabel() {
        let labelDetector = vision.cloudLabelDetector()  // Check console for errors.
        let image = VisionImage(image: imageView.image!)
        
        // Start activity indicator
        self.detectLabelActivityIndicator.startAnimating()
        self.detectItemButton.isEnabled = false
        
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
                self.detectItemButton.isEnabled = true
            }
        }
    }
    
    /*
     Detect text in image and apply it to the item's textContent.
     
     References: https://firebase.google.com/docs/ml-kit/ios/recognize-text
    */
    func detectText() {
        let textDetector = vision.cloudTextDetector()  // Check console for errors.
        let image = VisionImage(image: imageView.image!)
        
        // Start activity indicator
        self.detectTextActivityIndicator.startAnimating()
        self.detectTextButton.isEnabled = false
        
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
            self.detectTextButton.isEnabled = true
            
        }
    }
    
    // MARK: Actions
    @IBAction func detectItemTapped(_ sender: Any) {
        detectLabel()
    }
    
    @IBAction func detectTextTapped(_ sender: Any) {
        detectText()
    }
    
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
    
    // MARK: Firebase Activities
    
    // Converts Date object to String
    private func dateToString(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss zzz"
        let date = formatter.string(from: (date))
        return date
    }
    
    /*
     Adds item to Firebase Database and Storage.
     
     References: https://firebase.google.com/docs/database/ios/read-and-write
                https://firebase.google.com/docs/storage/ios/upload-files
     */
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
        
        // Initialise variables for image upload
        let imageRef = self.storageRef.child("\(filename).jpg")
        var downloadURL: String!
        let metaData = StorageMetadata()
        metaData.contentType = "image/jpg"
        // Upload image to Firebase Storage
        let uploadTask = imageRef.putData(image, metadata: metaData) {(metaData,error) in
            if let error = error {
                print(error.localizedDescription)
                self.displayMessage("Error", message: "Could not upload item.")
                return
            }
            else {
                // Store download URL of image
                imageRef.downloadURL(completion: { url, error in
                    if let error = error {
                        print(error.localizedDescription)
                        self.displayMessage("Error", message: "Photo could not be uploaded. Please check your internet connection or try again later.")
                    } else {
                        downloadURL = url!.absoluteString
                        
                        // Place upload data into a dictionary
                        let uploadItem: NSDictionary = [
                            "image" : downloadURL as NSString,
                            "date": date as NSString,
                            "title" : title as NSString? ?? "",
                            "textContent" : textContent as NSString? ?? "",
                            "latitude" : latitude as NSNumber? ?? 0,
                            "longitude" : longitude as NSNumber? ?? 0
                        ]
                        
                        // Upload item data
                        self.databaseRef.child("\(filename)").setValue(uploadItem)
                        self.dismiss(animated: true, completion: nil)
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
    
    // Updates an item's value in Firebase Database and Locally.
    private func editItemOnFirebase() {
        let filename = item?.filename
        let title = titleTextField.text
        let textContent = textContentTextField.text
        
        // Update item in database
        self.databaseRef.child("\(filename!)").updateChildValues(["title": title ?? "", "textContent": textContent ?? ""]) { (error, ref) in
            if let error = error {
                print(error.localizedDescription)
                self.displayMessage("Error", message: "Item could not be updated. Please check your internet connection or try again later.")
                return
            }
            else {
                // Update Item Locally
                self.item?.title = title!
                self.item?.textContent = textContent!
                self.delegate?.update() // Tell ViewItemTableView to update its view
                self.dismiss(animated: true, completion: nil)
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
        // Only show save location toggle if adding new item
        if newItem {
            return 5    // Adds save location toggle
        }
        else {
            return 4
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

}
