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
    
    // Toggle Firebase usage
    var firebaseSync = false
    
    // Managed Object Context and Initilisation Constructure for using Core Data.
    private var managedObjectContext: NSManagedObjectContext
    required init(coder aDecoder: NSCoder) {
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        managedObjectContext = (appDelegate?.persistentContainer.viewContext)!
        super.init(coder: aDecoder)!
    }
    
    // Core Data variables
    var item: Item?
    
    // Firebase Storage and Database
    var databaseRef = Database.database().reference().child("images")
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
        fetchItemsFromCoreData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        fetchItemsFromCoreData()
        
        self.collectionView?.reloadSections([0])
    
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Fetch Data
    
    // Fetch items from Core Data
    private func fetchItemsFromCoreData() {
        // Fetch Items from Core Data
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Item")
        do {
            currentItems = try managedObjectContext.fetch(fetchRequest) as! [Item]
            if currentItems.count == 0 {
                // Insert test data here ()
                currentItems = try managedObjectContext.fetch(fetchRequest) as! [Item]
            }
            itemList = currentItems     // Update local array with fetched books.
        }
        catch let error {
            print("Could not fetch \(error)")
        }
    }
    
    // Fetch items from Firebase
    private func fetchItemsFromFirebase() {
        // Load images from firebase
        let userID = Auth.auth().currentUser!.uid
        let userRef = databaseRef.child("users").child("\(userID)")
        
        userRef.observeSingleEvent(of: .value, with: {(snapshot) in
            // Get user value
            guard let value = snapshot.value as? NSDictionary else {
                return
            }
            
            for(_, link) in value {
                let url = link as! String
                
                if (!self.itemURLList.contains(url)) {
                    self.itemURLList.append(url)
                    self.storageRef.reference(forURL: url).getData(maxSize: 5 * 1024 * 1024, completion: {
                        (data, error) in
                        if let error = error {
                            print(error.localizedDescription)
                        } else {
                            //let image = UIImage(data: data!)
                            //self.itemList.append(image!)
                            self.collectionView?.insertItems(at: [IndexPath(row: self.itemList.count - 1, section: 0)])
                            self.collectionView?.reloadSections([0])
                        }
                    })
                }
            }
        }) { (error) in
            print(error.localizedDescription)
        }
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
    
    // MARK: - Upload Photo to Firebase
    
    private func uploadItemToFirebase() {
        guard let userID = Auth.auth().currentUser?.uid else {
            displayErrorMessage("Firebase User ID is invalid.")
            return
        }
        guard let image = photo else {
            displayErrorMessage("Cannot upload unitl a photo has been taken")
            return
        }
        
        let date = UInt(Date().timeIntervalSince1970)
        var data = Data()
        data = UIImageJPEGRepresentation(image, 0.8)!
        
        let imageRef = storageRef.reference().child("\(userID)/\(date).jpg")
        
        // Set upload path
        let metaData = StorageMetadata()
        metaData.contentType = "image/jpg"
        imageRef.putData(data, metadata: metaData) {(metaData,error) in
            if let error = error {
                print(error.localizedDescription)
                self.displayErrorMessage("Photo failed to upload")
                return
            }
            else {
                // Store download URL
                let downloadURL = StorageReference.downloadURL(completion:)
                self.databaseRef.child("users").child(userID).updateChildValues(["\(date)": downloadURL])
                print("Photo uploaded!")
                //self.navigationController?.popViewController(animated: true)
            }
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
        let imageData = itemList[indexPath.row].image as Data?
        cell.imageView.image = UIImage(data: imageData!)
        
        // Set Date
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm dd/MM/YYY"
        let date = formatter.string(from: (itemList[indexPath.row].date)!)
        cell.dateLabel.text = date
        
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

