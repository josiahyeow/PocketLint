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
import Hero

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
    
    // Hero animation IDs
    var imageHeroId: String?
    var titleHeroId: String?
    var dateHeroId: String?
    var menuHeroId: String?
    
    weak var delegate: ViewItemTableViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.allowsSelection = false  // Turn off table cell highlighting
        
        // Set animation hero IDs
        imageView.hero.id = imageHeroId
        titleLabel.hero.id = titleHeroId
        dateLabel.hero.id = dateHeroId
        menuButton.hero.id = menuHeroId
        
        self.navigationController?.hero.isEnabled = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // Update view with item content
        // Add image
        imageView.image = item?.image
        
        // Add Text
        self.title = item?.title
        titleLabel.text = item?.title
        textContentTextView.text = item?.textContent
        
        // Set date label
        let formatter = DateFormatter()
        //formatter.dateFormat = "h:mm a d MMM YYYY"
        formatter.dateStyle = .medium
        formatter.doesRelativeDateFormatting = true
        let itemDate = formatter.string(from: (item?.date)!)
        dateLabel.text = itemDate.uppercased()
        
        // Show map if longitude and latitude was saved
        if(((item?.longitude) != 0) && ((item?.latitude) != 0)) {
            self.locationMapView.isHidden = false
            // Add pin to map
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: (item?.latitude)!, longitude: (item?.longitude)!)
            locationMapView.addAnnotation(annotation)
            locationMapView.showAnnotations([annotation], animated: true)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // Update item values on edit
    func updateItem(title: String, textContent: String) {
        item?.title = title
        item?.textContent = textContent
        self.viewWillAppear(true)   // Update current view to reflect the changes
        self.delegate?.update() // Update PocketView to reflect the changes
    }
    
    // MARK: - Menu action sheet
    
    @IBAction func menuTapped(_ sender: Any) {
        let alertController = UIAlertController(title: "Menu", message: nil, preferredStyle: .actionSheet)
        
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
        
        
        alertController.addAction(editButton)
        alertController.addAction(deleteButton)
        alertController.addAction(cancelButton)
        
        self.navigationController!.present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func closeButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func handlePan(_ sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .began:
            hero.dismissViewController()
        case .changed:
            let translation = sender.translation(in: nil)
            let progress = translation.y / 2 / view.bounds.height
            Hero.shared.update(progress)
        default:
            Hero.shared.finish()
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
                itemVC.delegate = self
            }
        }
    }


}
