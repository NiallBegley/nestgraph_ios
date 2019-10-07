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

class SummaryTableViewController: UITableViewController, RecordControllerDelegate, SettingsDelegate, UIAdaptivePresentationControllerDelegate {
    
    @IBOutlet var tableview: UITableView!
    var persistentContainer: NSPersistentContainer?
    let AUTHORIZATION_SEGUE = "AUTHORIZATION_SEGUE"
    let CHART_SEGUE = "CHART_SEGUE"
    var recordController : RecordController?
    var devices : [Device] = []
    var showingSetup = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let navVC = self.navigationController as? SummaryNavigationController {
            persistentContainer = navVC.persistentContainer
            
            if persistentContainer != nil {
                recordController = RecordController.init(container: persistentContainer!)
                recordController?.delegate = self
                
                recordController?.deleteOldRecords()
                
                recordController?.refreshRecordsForAllDevices {
                    self.extractData()
                    DispatchQueue.main.async() {
                        self.refreshControl?.endRefreshing()
                        
                    }
                }
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
        
        DispatchQueue.main.async() {
            self.refreshControl?.beginRefreshing()
        }
        
        refreshControl?.addTarget(self, action: #selector(buttonClickedRefresh(_:)), for: .valueChanged)
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        tableview.reloadData()
    }
    
    func extractData() {
        
        //TODO: There's a problem here where the refresh is changing the device data array from under the tableview controller since we perform this in a background thread.  Needs to be addressed.
        devices = recordController?.getDevices() ?? []
        
        DispatchQueue.main.async() {
            self.tableview.reloadData()
        }
    }
    
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        if showingSetup {
            extractData()
            showingSetup = false
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == AUTHORIZATION_SEGUE,
            let vc = segue.destination as? SetupViewController
        {
            showingSetup = true
            vc.isModalInPresentation = true
            vc.persistentContainer = persistentContainer
            vc.presentationController?.delegate = self
        }
        else if segue.identifier == "SETTINGS_SEGUE",
            let vc = segue.destination as? SettingsTableViewController
        {
            vc.persistentContainer = persistentContainer
            vc.delegate = self
        }
        else if segue.identifier == CHART_SEGUE,
            let vc = segue.destination as? ChartViewController,
            let indexPath = sender as? IndexPath,
            persistentContainer != nil {
            
                //Handle the case of the external data
                if indexPath.section < devices.count {
                    vc.device = devices[indexPath.section]
                }
                
                vc.persistentContainer = persistentContainer!
        }
    }
    
    func refresh() {
        print("Refreshing")
        DispatchQueue.main.async() {
            self.refreshControl?.beginRefreshing()
        }
  
        recordController?.refreshRecordsForAllDevices {
            self.extractData()
            DispatchQueue.main.async() {
                self.refreshControl?.endRefreshing()
                
            }
        }
    }
    
    // MARK: - Buttons
    @objc func buttonClickedRefresh(_ sender: Any) {
        self.refresh()
        
    }
    
    // MARK: - RecordControllerDelegate
    func failedAuthorization() {
         guard let authVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "AUTHORIZATION_VIEW_CONTROLLER") as? AuthorizationViewController else { return }
        authVC.reauthorization = true
        showingSetup = true
        
        DispatchQueue.main.async() {
            self.refreshControl?.endRefreshing()
            self.present(authVC, animated: true, completion: nil)
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
        
        
        if !externalSection {
            
            guard let high = recordController?.highestInternalTemp(forDevice: device),
                let low = recordController?.lowestInternalTemp(forDevice: device),
                let current = recordController?.currentRecord(forDevice: device) else { return cell }
            
            cell.setHigh(Int(high.internal_temp))
            cell.setLow(low.internal_temp)
            cell.setCurrent(current.internal_temp)
            cell.accessoryType = .disclosureIndicator
            cell.selectionStyle = .blue
            cell.labelConstraint.constant = 0
        }
        else {
            
            guard let high = recordController?.highestExternalTemp(forDevice: device),
                let low = recordController?.lowestExternalTemp(forDevice: device),
                let current = recordController?.currentRecord(forDevice: device) else { return cell }
            
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

