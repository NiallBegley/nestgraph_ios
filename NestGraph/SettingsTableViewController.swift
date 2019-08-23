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
        recordController?.deleteAll()
        navigationController?.popViewController(animated: true)
        delegate?.didEraseAll()
        
    }

}
