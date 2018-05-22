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
    var userID: String?
    var databaseRef = Database.database().reference()
    var storageRef = Storage.storage()
    var connected = true
    
    // Initialise list to store images and image urls
    var currentItems = [Item]()
    var itemList = [Item]()
    
    // Collection View variables
    private let reuseIdentifier = "itemCell"
    private let sectionInsets = UIEdgeInsets(top: 50.0, left: 20.0, bottom: 50.0, right: 20.0)
    private var itemsPerRow: CGFloat =  1
    
    // Photo capture variables
    private var photo: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Hides navigation bar outline
        self.navigationController?.navigationBar.shadowImage = UIImage()
        
        let defaults = UserDefaults.standard
        // Set user preferences
        defaults.set("Newest First", forKey: "sortOrder")
        defaults.set(true, forKey: "textDetection")
        defaults.set(true, forKey: "saveLocation")
        defaults.set(0, forKey: "itemSize")
        
        // Get Firebase userID and database reference path
        guard let getUserID = Auth.auth().currentUser?.uid else {
            displayErrorMessage("Firebase User ID is invalid.")
            return
        }
        userID = getUserID
        databaseRef = Database.database().reference().child("users").child("\(userID!)")
        
        // Get connection status
        let connectedRef = Database.database().reference(withPath: ".info/connected")
        connectedRef.observe(.value, with: { snapshot in
            if snapshot.value as? Bool ?? false {
                self.connected = true
            } else {
                self.connected = false
            }
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.navigationBar.prefersLargeTitles = true
        
        self.fetchItemsFromFirebase()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func updateTitle() {
        self.navigationItem.title = "\(self.itemList.count) items"
    }
    
    // MARK: - Actions
    
    @IBAction func settingsButton(_ sender: Any) {
        self.performSegue(withIdentifier: "settingsSegue", sender: Any?.self)
    }
    
    @IBAction func addButtonPressed(_ sender: Any) {
        // Take photo if connected to Firebase
        if connected {
            takePhoto()
        }
        else {
            displayErrorMessage("Unable to add item when offline.")
        }
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
        
        databaseRef.observe(.value, with: { (snapshot) in
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
                        self.collectionView?.insertItems(at:[IndexPath(row: self.itemList.count - 1, section: 0)])
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
                                self.collectionView?.insertItems(at: [IndexPath(row: self.itemList.count - 1 , section: 0)])
                                self.collectionView?.reloadSections([0])
                            }
                        })
                    }
                }
            }
            self.updateTitle()
            
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
    
    // MARK: Take Photo
    
    // Take photo
    func takePhoto() {
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
    
    // MARK: Data Management
    
    // Deletes and item
    func deleteItem(cell: ItemCollectionViewCell) {
        if let indexPath = collectionView?.indexPath(for: cell) {
            // Delete item from Firebase
            let item = itemList[indexPath.item]
            databaseRef.child("\(item.filename)").removeValue()
            storageRef.reference(forURL: item.imageURL).delete(completion: { (error) in
                if let error = error {
                    print(error.localizedDescription)
                    return
                } else {
                    // Delete item from itemList
                    self.itemList.remove(at: indexPath.item)
                    self.updateTitle()
                    
                    // Delete item from collectionView
                    self.collectionView?.deleteItems(at: [indexPath])
                }
                })
        }
        
    }
    
    // Sort Items
    
    func sortItems() {
        if UserDefaults.standard.object(forKey: "sortOrder") as! String == "Newest First" {
            itemList = itemList.sorted(by: { $0.filename > $1.filename })
        }
        else if UserDefaults.standard.object(forKey: "sortOrder") as! String == "Oldest First" {
            itemList = itemList.sorted(by: { $0.filename < $1.filename })
        }
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
        
        // Sort items before rendering new cells
        self.sortItems()
        
        // Configure the cell
        
        // Add cell styling
        cell.contentView.layer.cornerRadius = 16
        cell.contentView.layer.masksToBounds = true;
        
        cell.layer.shadowColor = UIColor.black.cgColor
        cell.layer.shadowOffset = CGSize(width:0,height: 8)
        cell.layer.shadowRadius = 12
        cell.layer.shadowOpacity = 0.15
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
        
        // Connect cell to delegate which allows the menu button to function
        cell.delegate = self
        
        if itemsPerRow > 1 {
            cell.dateLabel.isHidden = true
            cell.menuButton.isHidden = true
            cell.titleLabel.isHidden = true
        }
        else {
            cell.dateLabel.isHidden = false
            cell.menuButton.isHidden = false
            cell.titleLabel.isHidden = false
        }
        
        return cell
    }
    
    // MARK: UICollectionViewDelegateFlowLayout
    
    func collectionView(_ collectionView: UICollectionView, layout
        collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath:
        IndexPath) -> CGSize {
        let paddingSpace = sectionInsets.left * (itemsPerRow + 1)
        let availableWidth = view.frame.width - paddingSpace * 1.2
        let widthPerItem = availableWidth / itemsPerRow
        
        if itemsPerRow > 1 {
            return CGSize(width: widthPerItem, height: widthPerItem)
        }
        else {
            return CGSize(width: widthPerItem, height: widthPerItem + widthPerItem/3.5)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout
        collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    
    func collectionView(_ collectionView: UICollectionView, layout
        collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.left * 1.2
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Add Edit Item Segue
        if segue.identifier == "addItemSegue" {
            if let destinationVC = segue.destination as? UINavigationController {
                // Pass the information of the book to the next screen.
                let photoVC = destinationVC.viewControllers.first! as! AddEditItemTableViewController
                photoVC.photo = photo
            }
        }
        
        // View Item Segue
        if segue.identifier == "viewItemSegue" {
            if let destinationVC = segue.destination as? UINavigationController {
                destinationVC.hero.isEnabled = true
                let viewItemVC = destinationVC.viewControllers.first! as! ViewItemTableViewController
                let cell = sender as! ItemCollectionViewCell
                let indexPath = self.collectionView!.indexPath(for: cell)
                print(indexPath!)
                viewItemVC.item = itemList[indexPath![1]]
                viewItemVC.cell = cell
                viewItemVC.delegate = self
                
                // Set Hero animation IDs for cell and view item
                let imageHeroId = "itemImage\(String(indexPath![1]))"
                let titleHeroId = "itemTitle\(String(indexPath![1]))"
                let dateHeroId = "itemDate\(String(indexPath![1]))"
                let menuHeroId = "itemMenu\(String(indexPath![1]))"
                cell.imageView.hero.id = imageHeroId
                cell.titleLabel.hero.id = titleHeroId
                cell.dateLabel.hero.id = dateHeroId
                cell.menuButton.hero.id = menuHeroId
                
                viewItemVC.imageHeroId = imageHeroId
                viewItemVC.titleHeroId = titleHeroId
                viewItemVC.dateHeroId = dateHeroId
                viewItemVC.menuHeroId = menuHeroId
            }
        }
        
        // Settings Segue
        if segue.identifier == "settingsSegue" {
            if let destinationVC = segue.destination as? SettingsTableViewController {
                destinationVC.delegate = self
                
                // Set back button to say back
                let backItem = UIBarButtonItem()
                backItem.title = "Back"
                navigationItem.backBarButtonItem = backItem
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

// Delegate for ItemCollectionViewCell which allows item menu to function
extension PocketCollectionViewController: ItemCollectionViewCellDelegate {
    func showMenu(cell: ItemCollectionViewCell) {
        let alertController = UIAlertController(title: "Menu", message: nil, preferredStyle: .actionSheet)
        
        
        let  deleteButton = UIAlertAction(title: "Remove", style: .destructive, handler: { (action) -> Void in
            self.deleteItem(cell: cell)
        })
        
        let cancelButton = UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) -> Void in
            print("Cancel button tapped")
        })
        
        
        alertController.addAction(deleteButton)
        alertController.addAction(cancelButton)
        
        self.navigationController!.present(alertController, animated: true, completion: nil)
    }
}

// Delegate for ItemCollectionViewCell which allows item menu to function
extension PocketCollectionViewController: ViewItemTableViewControllerDelegate {
    func delete(cell: ItemCollectionViewCell) {
        self.deleteItem(cell: cell)
    }
    
    func update() {
        self.collectionView?.reloadSections([0])
    }
}

// Delegate for Settings which reloads the items to update sort order
extension PocketCollectionViewController: SettingsTableViewControllerDelegate {
    func reloadSections() {
        // Set itemSize
        let defaults = UserDefaults.standard
        var itemSize = defaults.object(forKey: "itemSize") as! CGFloat
        itemSize += 1
        itemsPerRow = itemSize
        // Reload sections to update sort order
        self.collectionView?.reloadSections([0])
    }
}

