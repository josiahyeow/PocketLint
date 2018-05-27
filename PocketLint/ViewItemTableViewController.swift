//
//  ViewItemTableViewController.swift
//  PocketLint
//
//  Created by Josiah Yeow on 28/4/18.
//  Copyright © 2018 Josiah Yeow. All rights reserved.
//
// This TableViewController displays an item's image, title, text content and location.
// It also contains a menu which allows the user to share, edit or remove the current item.

import UIKit
import MapKit
import Firebase
import Hero


// This tell's the CollectionView to delete this item and update it's data when the user selects "Remove" from the menu.
protocol ViewItemTableViewControllerDelegate: class {
    func delete(cell: ItemCollectionViewCell)
    func update()
}

class ViewItemTableViewController: UITableViewController, AddEditItemTableViewControllerDelegate {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var menuButton: UIButton!
    @IBOutlet weak var textContentTextView: UITextView!
    @IBOutlet weak var locationMapView: MKMapView!
    
    var item: Item?
    var cell: ItemCollectionViewCell?
    
    // Initialise Hero animation IDs.
    var imageHeroId: String?
    var titleHeroId: String?
    var dateHeroId: String?
    var menuHeroId: String?
    
    weak var delegate: ViewItemTableViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.allowsSelection = false  // Turn off table cell highlighting.
        
        // Set animation hero IDs.
        imageView.hero.id = imageHeroId
        titleLabel.hero.id = titleHeroId
        dateLabel.hero.id = dateHeroId
        menuButton.hero.id = menuHeroId
        
        self.navigationController?.hero.isEnabled = true
        
        self.tableView.scrollsToTop = true
    
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.title = ""
        
        // Update view with item content.
        
        imageView.image = item?.image   // Add image
        titleLabel.text = item?.title   // Add title
        setAndResizeTextContent()       // Add text view and update height
        setDate()                       // Set date label
        initMap()                       // Initialise the map
        
        // Resize tableview cell to fit content.
        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableViewAutomaticDimension
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Data Initialisation Functions
    
    // Set and resize textContent view based on the length of its contents.
    func setAndResizeTextContent() {
        textContentTextView.text = item?.textContent
        let size = CGSize(width: textContentTextView.frame.size.width, height: .infinity)
        let estimatedSize = textContentTextView.sizeThatFits(size)
        textContentTextView.constraints.forEach { (constraint) in
            if constraint.firstAttribute == .height {
                constraint.constant = estimatedSize.height
            }
        }
    }
    
    // Set the date and format.
    func setDate() {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.doesRelativeDateFormatting = true
        let itemDate = formatter.string(from: (item?.date)!)
        dateLabel.text = itemDate.uppercased()
    }
    
    // Initialise and show the map if longitude and latitude was saved.
    func initMap() {
        if(((item?.longitude) != 0) && ((item?.latitude) != 0)) {
            self.locationMapView.isHidden = false
            // Add pin to map
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: (item?.latitude)!, longitude: (item?.longitude)!)
            locationMapView.addAnnotation(annotation)
            locationMapView.showAnnotations([annotation], animated: true)
        }
    }
    
    // Update item values on edit.
    func update() {
        self.viewWillAppear(true)   // Update current view to reflect the changes
        self.delegate?.update() // Update PocketView to reflect the changes
    }
    
    // MARK: - Actions
    
    // Displays menu with Share, Edit, Remove and Cancel options.
    @IBAction func menuTapped(_ sender: Any) {
        let alertController = UIAlertController(title: "Menu", message: nil, preferredStyle: .actionSheet)
        
        let shareButton = UIAlertAction(title: "Share", style: .default, handler: { (action) -> Void in
            self.shareImage()
        })
        
        let editButton = UIAlertAction(title: "Edit", style: .default, handler: { (action) -> Void in
            self.performSegue(withIdentifier: "editItemSegue", sender: Any?.self)
        })
        
        let deleteButton = UIAlertAction(title: "Remove", style: .destructive, handler: { (action) -> Void in
            self.delegate?.delete(cell: self.cell!)
            self.dismiss(animated: true, completion: nil)
            
        })
        
        let cancelButton = UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) -> Void in
            print("Cancel button tapped")
        })
        
        alertController.addAction(shareButton)
        alertController.addAction(editButton)
        alertController.addAction(deleteButton)
        alertController.addAction(cancelButton)
        
        self.navigationController!.present(alertController, animated: true, completion: nil)
    }
    
    
    // Dismisses view controller when close button is tapped.
    @IBAction func closeButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    

    // Dismisses view controller with a swipe down gesture.
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if (scrollView.contentOffset.y < -200) {
            hero.dismissViewController()
        }
    }
    
    
    /*
     Displays an Activity Controller which allows user to share the image with various applications.
     
     References: https://stackoverflow.com/questions/35931946/basic-example-for-sharing-text-or-image-with-uiactivityviewcontroller-in-swift
     */
    func shareImage() {
        let imageToShare:[UIImage] = [(item?.image)!]
        let activityController = UIActivityViewController(activityItems: imageToShare , applicationActivities: nil)
        activityController.popoverPresentationController?.sourceView = self.view
        
        self.present(activityController, animated: true, completion: nil)
    }
    
    /*
     Allows the image to be zoomed in and out using a pinch gesture.
     
     References: https://medium.com/@jeremysh/instagram-pinch-to-zoom-pan-gesture-tutorial-772681660dfe
     */
    @IBAction func handlePinch(_ sender: UIPinchGestureRecognizer) {
        if sender.state == .changed {
            imageView.transform = imageView.transform.scaledBy(x: sender.scale,
                                                               y: sender.scale)
            sender.scale = 1
        } else if sender.state == .ended {
            UIView.animate(withDuration: 0.3, animations: {
                self.imageView.transform = CGAffineTransform.identity
            })
        }
    }
    

    // Displays an alert message with a specified title and message.
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


    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "editItemSegue" {
            if let destinationVC = segue.destination as? UINavigationController {
                // Pass the information of the book to the first View Controller connected to the Navigation Controller.
                let itemVC = destinationVC.viewControllers.first! as! AddEditItemTableViewController
                itemVC.item = item
                itemVC.delegate = self
            }
        }
    }


}
