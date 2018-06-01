//
//  SettingsTableViewController.swift
//  PocketLint
//
//  Created by Josiah Yeow on 15/5/18.
//  Copyright © 2018 Josiah Yeow. All rights reserved.
//

import UIKit
import Firebase

protocol SettingsTableViewControllerDelegate: class {
    func reloadSections()
}

class SettingsTableViewController: UITableViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    @IBOutlet weak var sortOrderInputField: UITextField!
    @IBOutlet weak var itemDetectionSwitch: UISwitch!
    @IBOutlet weak var textDetectionSwitch: UISwitch!
    @IBOutlet weak var saveLocationSwitch: UISwitch!
    
    @IBOutlet weak var itemSizeSegmentedControl: UISegmentedControl!
    
    weak var delegate: SettingsTableViewControllerDelegate?
    
    let defaults = UserDefaults.standard
    
    let sortOptions = ["Newest First", "Oldest First"]
    
    var sortOptionsPickerView = UIPickerView()
    

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.prefersLargeTitles = false
        self.title = "Settings"
        
        // Set up UI picker view
        // Reference: https://www.youtube.com/watch?v=QdLFd3wNqV8
        sortOptionsPickerView.delegate = self
        sortOptionsPickerView.dataSource = self
        sortOrderInputField.inputView = sortOptionsPickerView
        
        // Get sort option
        sortOrderInputField.text = defaults.object(forKey: "sortOrder") as? String
        
        // Get detection values
        if defaults.object(forKey: "itemDetection") as! Bool {
            itemDetectionSwitch.isOn = true
        }
        else {
            itemDetectionSwitch.isOn = false
        }
        if defaults.object(forKey: "textDetection") as! Bool {
            textDetectionSwitch.isOn = true
        }
        else {
            textDetectionSwitch.isOn = false
        }
        
        // Get save location value
        if defaults.object(forKey: "saveLocation") as! Bool {
            saveLocationSwitch.isOn = true
        }
        else {
            saveLocationSwitch.isOn = false
        }
        
        itemSizeSegmentedControl.selectedSegmentIndex = defaults.object(forKey: "itemSize") as! Int
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        defaults.set(sortOrderInputField.text, forKey: "sortOrder")
        defaults.set(itemDetectionSwitch.isOn, forKey: "itemDetection")
        defaults.set(textDetectionSwitch.isOn, forKey: "textDetection")
        defaults.set(saveLocationSwitch.isOn, forKey: "saveLocation")
        print(itemSizeSegmentedControl.selectedSegmentIndex)
        defaults.set(itemSizeSegmentedControl.selectedSegmentIndex, forKey: "itemSize")
        
        self.delegate?.reloadSections()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Picker view data source
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return sortOptions.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return sortOptions[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        sortOrderInputField.text = sortOptions[row]
        //sortOrderInputField.resignFirstResponder()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 5
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if section < 2 {
            return 2
        }
        else {
            return 1
        }
    }
    
    // Mark - Actions Log Out
    
    @IBAction func signOut(_ sender: Any) {
        do {
            try Auth.auth().signOut()
        } catch {}
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    private func saveAndReturn() {
        
        navigationController?.popViewController(animated: true)
    }

}
