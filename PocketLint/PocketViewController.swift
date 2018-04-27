//
//  PocketViewController.swift
//  PocketLint
//
//  Created by Josiah Yeow on 23/4/18.
//  Copyright © 2018 Josiah Yeow. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import FirebaseStorage

class PocketViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    // Firebase Storage and Database
    var databaseRef = Database.database().reference().child("images")
    var storageRef = Storage.storage()
    
    // Initialise list to store images and image urls
    var itemList = [UIImage]()
    var itemURLList = [String]()
    
    // Collection View parameters
    private let reuseIdentifier = "itemCell"
    private let sectionInsets = UIEdgeInsets(top: 50.0, left: 20.0, bottom: 50.0, right: 20.0)
    private let itemsPerRow: CGFloat = 1

    // Photo capture parameters
    private var newPhoto: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.prefersLargeTitles = true
        
        // Set delegate and data source to collection view
        collectionView.delegate = self
        collectionView.dataSource = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
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
                            let image = UIImage(data: data!)
                            self.itemList.append(image!)
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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Actions
    
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
        self.present(controller, animated: true, completion: {
            self.uploadPhoto()
        })
    }
    
    @IBAction func signOut(_ sender: Any) {
        do {
            try Auth.auth().signOut()
        } catch {}
        navigationController?.popViewController(animated: true)
        self.dismiss(animated:true, completion: nil)
    }
    
    // MARK: - Upload Photo
    
    private func uploadPhoto() {
        guard let userID = Auth.auth().currentUser?.uid else {
            displayErrorMessage("Firebase User ID is invalid.")
            return
        }
        guard let image = newPhoto else {
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
                let downloadURL = metaData!.downloadURL()!.absoluteString
                self.databaseRef.child("users").child(userID).updateChildValues(["\(date)": downloadURL])
                print("Photo uploaded!")
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String: Any]) {
        if let pickedImage = info[UIImagePickerControllerEditedImage] as? UIImage {
            newPhoto = pickedImage
        }
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        displayErrorMessage("There was an error in getting the photo")
        self.dismiss(animated: true, completion: nil)
    }
    
    func displayErrorMessage(_ errorMessage: String) {
        let alertController = UIAlertController(title: "Error", message: errorMessage, preferredStyle: UIAlertControllerStyle.alert)
        
        alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default, handler: nil))
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    // MARK: UICollectionViewDataSource
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return itemList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! ItemCollectionViewCell
        
        // Configure the cell
        cell.backgroundColor = UIColor.lightGray
        cell.imageView.image = itemList[indexPath.row]
        
        return cell
    }
    
    // MARK: UICollectionViewDelegateFlowLayout
    
    func collectionView(_ collectionView: UICollectionView, layout
        collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath:
        IndexPath) -> CGSize {
        let paddingSpace = sectionInsets.left * (itemsPerRow + 1)
        let availableWidth = view.frame.width - paddingSpace
        let widthPerItem = availableWidth / itemsPerRow
        
        return CGSize(width: widthPerItem, height: widthPerItem)
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
