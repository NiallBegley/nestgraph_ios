//
//  ViewController.swift
//  NestGraph
//
//  Created by Niall on 7/15/19.
//  Copyright © 2019 Niall. All rights reserved.
//


import UIKit
import CoreData
import KeychainSwift

class SummaryTableViewController: UITableViewController, RecordControllerDelegate, SettingsDelegate {
    
    @IBOutlet var tableview: UITableView!
    var persistentContainer: NSPersistentContainer?
    private let AUTHORIZATION_SEGUE = "AUTHORIZATION_SEGUE"
    private let CHART_SEGUE = "CHART_SEGUE"
    private var recordController : RecordController?
    private var devices : [Device] = []
    private var showingSetup = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let navVC = self.navigationController as? SummaryNavigationController {
            persistentContainer = navVC.persistentContainer
            
            if persistentContainer != nil {
                recordController = RecordController.init(container: persistentContainer!)
                recordController?.delegate = self
            }
        } else {
            fatalError()
        }
        
        if recordController?.getDevices().count == 0
        {
            DispatchQueue.main.async(){
                self.performSegue(withIdentifier:self.AUTHORIZATION_SEGUE, sender: self)
            }
        }
        else
        {
            refreshControl?.beginRefreshing()
            extractData()
            DispatchQueue.global(qos: .background).async {
                self.refresh()
            }
        }
        
        refreshControl?.addTarget(self, action: #selector(buttonClickedRefresh(_:)), for: .valueChanged)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        extractData()
        tableview.reloadData()
    }
    
    func extractData() {
        
        //TODO: There's a problem here where the refresh is changing the device data array from under the tableview controller since we perform this in a background thread.  Needs to be addressed.
        devices = recordController?.getDevices() ?? []
        
        DispatchQueue.main.async() {
            self.tableview.reloadData()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == AUTHORIZATION_SEGUE
        {
            showingSetup = true
            if let vc = segue.destination as? SetupViewController {
                vc.persistentContainer = persistentContainer
            }
        }
        else if segue.identifier == "SETTINGS_SEGUE"
        {
            if let vc = segue.destination as? SettingsTableViewController {
                vc.persistentContainer = persistentContainer
                vc.delegate = self
            }
        }
        else if segue.identifier == CHART_SEGUE {
            if let vc = segue.destination as? ChartViewController,
                let indexPath = sender as? IndexPath,
                persistentContainer != nil {
                
                //Handle the case of the external data
                if indexPath.section < devices.count {
                    vc.device = devices[indexPath.section]
                }
                
                vc.persistentContainer = persistentContainer!
            }
        }
    }
    
    func refresh() {
        print("Refreshing")
        recordController?.refreshRecordsForAllDevices {
            self.extractData()
            DispatchQueue.main.async() {
                self.refreshControl?.endRefreshing()
                
            }
        }
    }
    
    // MARK: - Buttons
    @IBAction func buttonClickedRefresh(_ sender: Any) {
        self.refreshControl?.endRefreshing()
        self.refresh()
        
    }
    
    func failedAuthorization() {
         guard let authVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "AUTHORIZATION_VIEW_CONTROLLER") as? AuthorizationViewController else { return }
        authVC.reauthorization = true
        
        DispatchQueue.main.async() {
            self.present(authVC, animated: true, completion:  {
                self.refreshControl?.endRefreshing()
                self.refresh()
            })
        }
    }
    
    func failedNetworking() {
        DispatchQueue.main.async() {
            self.refreshControl?.endRefreshing()
            
        }
    }
    
    // MARK: - TableViewDelegate
    override func numberOfSections(in tableView: UITableView) -> Int {
        return devices.count > 0 ? devices.count + 1 : 0
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DEVICE_CELL") as! DeviceSummaryTableViewCell
        let externalSection = (indexPath.section == numberOfSections(in: tableView) - 1)
        
        let device = devices[externalSection ? 0 : indexPath.section]
        
        guard let high = recordController?.highestInternalTemp(forDevice: device),
            let low = recordController?.lowestInternalTemp(forDevice: device),
            let current = recordController?.currentRecord(forDevice: device) else { return cell }
        
        if !externalSection {
            cell.setHigh(high.internal_temp)
            cell.setLow(low.internal_temp)
            cell.setCurrent(current.internal_temp)
            cell.accessoryType = .disclosureIndicator
            cell.selectionStyle = .blue
            cell.labelConstraint.constant = 0
        }
        else {
            cell.setHigh(Int(high.external_temp))
            cell.setLow(Int(low.external_temp))
            cell.setCurrent(Int(current.external_temp))
            cell.accessoryType = .none
            cell.selectionStyle = .none
            cell.labelConstraint.constant = -20
        }

        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 88.0
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section < devices.count ? devices[section].name_long : "External"
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let externalSection = (indexPath.section == numberOfSections(in: tableView) - 1)
        
        if !externalSection {
            performSegue(withIdentifier: "CHART_SEGUE", sender: indexPath)
        }
    }


    // MARK: - SettingsDelegate
    func didEraseAll() {
        DispatchQueue.main.async() {
            self.devices = []
            self.tableview.reloadData()
            self.performSegue(withIdentifier:self.AUTHORIZATION_SEGUE, sender: self)
        }
    }
}

