//
//  PocketCollectionViewController.swift
//  PocketLint
//
//  Created by Josiah Yeow on 27/4/18.
//  Copyright © 2018 Josiah Yeow. All rights reserved.
//

import UIKit
import CoreData
import Firebase

class PocketCollectionViewController: UICollectionViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UICollectionViewDelegateFlowLayout {
    
    // Firebase Storage and Database
    var databaseRef = Database.database().reference()
    var storageRef = Storage.storage()
    
    // Initialise list to store images and image urls
    var currentItems = [Item]()
    var itemList = [Item]()
    var itemURLList = [String]()
    
    // Collection View variables
    private let reuseIdentifier = "itemCell"
    private let sectionInsets = UIEdgeInsets(top: 50.0, left: 20.0, bottom: 50.0, right: 20.0)
    private let itemsPerRow: CGFloat = 1
    
    // Photo capture variables
    private var photo: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.prefersLargeTitles = true
        
    }
    
    override func viewWillAppear(_ animated: Bool) {

        self.fetchItemsFromFirebase()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Fetch Data
    
    // Convert date string to Date object
    private func stringToDate(date: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss zzz"
        let date = formatter.date(from: (date))
        return date!
    }
    
    // Fetch items from Firebase
    private func fetchItemsFromFirebase() {
        // Load images from firebase
        let userID = Auth.auth().currentUser!.uid
        let userRef = databaseRef.child("users").child("\(userID)")
        
        userRef.observeSingleEvent(of: .value, with: { (snapshot) in
            // Get user value
            guard let value = snapshot.value as? NSDictionary else {
                return
            }
            
            for(fileNameKey,itemValue) in value {
                let itemValues = itemValue as? NSDictionary
                let item = Item()
                item.filename = fileNameKey as! String
                item.imageURL = itemValues!["image"] as! String
                
                item.date = self.stringToDate(date: itemValues!["date"] as! String)
                
                item.title = itemValues!["title"] as! String
                item.textContent = itemValues!["textContent"] as! String
                item.latitude = itemValues!["latitude"] as! Double
                item.longitude = itemValues!["longitude"] as! Double
                
                if(!self.itemList.contains(where: { $0.filename == item.filename })) {
                    if(self.hasLocalImage(item: item)) {
                        self.loadLocalImage(item: item)
                        self.itemList.append(item)
                        self.collectionView?.insertItems(at:[IndexPath(row: 0, section: 0)])
                        self.collectionView?.reloadSections([0])
                    }
                    else {
                        self.storageRef.reference(forURL: item.imageURL).getData(maxSize: 5 * 1024 * 1024, completion: {
                            (data, error) in
                            if let error = error {
                                print(error.localizedDescription)
                            } else {
                                self.saveLocalImage(item: item, imageData: data!)
                                self.itemList.append(item)
                                self.collectionView?.insertItems(at: [IndexPath(row: 0, section: 0)])
                                self.collectionView?.reloadSections([0])
                            }
                        })
                    }
                }
                else {
                    // Update title if changed
                    if self.itemList.first(where:{ $0.filename == item.filename })?.title != item.title {
                        self.itemList.first(where:{ $0.filename == item.filename })?.title = item.title
                        self.collectionView?.reloadSections([0])
                    }
                    // Update textContent if changed
                    if self.itemList.first(where:{ $0.filename == item.filename })?.textContent != item.textContent {
                        self.itemList.first(where:{ $0.filename == item.filename })?.textContent = item.textContent
                        self.collectionView?.reloadSections([0])
                    }
                }
            }
            
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    // MARK: - Cache Items
    func hasLocalImage(item:Item) -> Bool {
        var localFileExists:Bool = false
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true) [0] as String
        let url = NSURL(fileURLWithPath: path)
        if let pathComponent = url.appendingPathComponent(item.filename) {
            let filePath = pathComponent.path
            
            let fileManager = FileManager.default
            localFileExists = fileManager.fileExists(atPath: filePath)
        }
        return localFileExists
    }
    
    func loadLocalImage(item:Item) {
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true) [0] as String
        let url = NSURL(fileURLWithPath: path)
        if let pathComponent = url.appendingPathComponent(item.filename) {
            let filePath = pathComponent.path
            let fileManager = FileManager.default
            let fileData = fileManager.contents(atPath: filePath)
            item.image = UIImage(data: fileData!)!
        }
    }
    
    func saveLocalImage(item: Item, imageData: Data) {
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true) [0] as String
        let url = NSURL(fileURLWithPath: path)
        if let pathComponent = url.appendingPathComponent(item.filename) {
            let filePath = pathComponent.path
            let fileManager = FileManager.default
            fileManager.createFile(atPath: filePath, contents: imageData, attributes: nil)
        }
        item.image = UIImage(data: imageData)!
        
    }
    
    // MARK: - Take Photo
    
    @IBAction func takePhoto(_ sender: Any) {
        let controller = UIImagePickerController()
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera) {
            controller.sourceType = UIImagePickerControllerSourceType.camera
        }
        else {
            controller.sourceType = UIImagePickerControllerSourceType.photoLibrary
        }
        controller.allowsEditing = true
        controller.delegate = self
        self.present(controller, animated: true, completion: nil)
    }
    
    // Function that returns image from the Camera
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String: Any]) {
        if let pickedImage = info[UIImagePickerControllerEditedImage] as? UIImage {
            photo = pickedImage
        }
        dismiss(animated: false, completion: {
            self.performSegue(withIdentifier: "addItemSegue", sender: Any?.self)
        })
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        displayErrorMessage("There was an error in getting the photo")
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func signOut(_ sender: Any) {
        do {
            try Auth.auth().signOut()
        } catch {}
        navigationController?.popViewController(animated: true)
        self.dismiss(animated:true, completion: nil)
    }
    
    
    // Error Message Template
    
    func displayErrorMessage(_ errorMessage: String) {
        let alertController = UIAlertController(title: "Error", message: errorMessage, preferredStyle: UIAlertControllerStyle.alert)
        
        alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default, handler: nil))
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    // MARK: UICollectionViewDataSource
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return itemList.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! ItemCollectionViewCell
        
        // Configure the cell
        
        // Add cell styling
        cell.contentView.layer.cornerRadius = 14.0
        cell.contentView.layer.masksToBounds = true;
        
        cell.layer.shadowColor = UIColor.black.cgColor
        cell.layer.shadowOffset = CGSize(width:0,height: 0)
        cell.layer.shadowRadius = 8.0
        cell.layer.shadowOpacity = 0.35
        cell.layer.masksToBounds = false;
        cell.layer.shadowPath = UIBezierPath(roundedRect:cell.bounds, cornerRadius:cell.contentView.layer.cornerRadius).cgPath
 
        // Set Image
        cell.imageView.image = itemList[indexPath.row].image
        
        // Set Date
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.doesRelativeDateFormatting = true
        let date = formatter.string(from: (itemList[indexPath.row].date))
        cell.dateLabel.text = date.uppercased()
        // Set Title
        cell.titleLabel.text = itemList[indexPath.row].title
        
        return cell
    }
    
    // MARK: UICollectionViewDelegateFlowLayout
    
    func collectionView(_ collectionView: UICollectionView, layout
        collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath:
        IndexPath) -> CGSize {
        let paddingSpace = sectionInsets.left * (itemsPerRow + 1)
        let availableWidth = view.frame.width - paddingSpace
        let widthPerItem = availableWidth / itemsPerRow
        
        return CGSize(width: widthPerItem, height: widthPerItem + widthPerItem/3)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout
        collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    
    func collectionView(_ collectionView: UICollectionView, layout
        collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.left
    }




    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Add Edit Item Segue
        if let destinationVC = segue.destination as? UINavigationController {
            // Pass the information of the book to the next screen.
            let photoVC = destinationVC.viewControllers.first! as! AddEditItemTableViewController
            photoVC.photo = photo
        }
        
        // View Item Segue
        if segue.identifier == "viewItemSegue" {
            if let destinationVC = segue.destination as? ViewItemTableViewController {
                let cell = sender as! UICollectionViewCell
                let indexPath = self.collectionView!.indexPath(for: cell)
                print(indexPath!)
                destinationVC.item = itemList[indexPath![1]]
            }
        }
    }



    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    
    }
    */

}

