//
//  SettingsTableViewController.swift
//  NestGraph
//
//  Created by Niall on 8/16/19.
//  Copyright © 2019 Niall. All rights reserved.
//

import UIKit
import CoreData

protocol SettingsDelegate : class{
    func didEraseAll()
}

class SettingsTableViewController: UITableViewController {

    var persistentContainer: NSPersistentContainer?
    private var recordController : RecordController?
    weak var delegate:SettingsDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let navVC = self.navigationController as? SummaryNavigationController {
            self.persistentContainer = navVC.persistentContainer
            
            if persistentContainer != nil {
                recordController = RecordController.init(container: persistentContainer!)
            }
        } else {
            fatalError()
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SETTINGS_CELL")
        
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.row == 0 {
            let alert = UIAlertController.init(title: "Warning", message: "Are you sure you want to erase all data?", preferredStyle: .alert)
            alert.addAction(UIAlertAction.init(title: "Yes", style: .destructive, handler: {(alert: UIAlertAction) in
                if let _ = self.recordController?.deleteAll() {
                    self.navigationController?.popViewController(animated: true)
                    self.delegate?.didEraseAll()
                } else {
                    let alert = UIAlertController.init(title: "Error", message: "Unable to erase all data - please try again", preferredStyle: .alert)
                    alert.addAction(UIAlertAction.init(title: "Okay", style: .cancel, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
            }))
            
            alert.addAction(UIAlertAction.init(title: "No", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
            
            
        }
        
    }

}
