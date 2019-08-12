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

class SummaryTableViewController: UITableViewController, RecordControllerDelegate {
    @IBOutlet var tableview: UITableView!
    var persistentContainer: NSPersistentContainer?
    private let AUTHORIZATION_SEGUE = "AUTHORIZATION_SEGUE"
    private var recordController : RecordController?
    private var devices : [Device] = []
    private var showingSetup = false
    
    @IBOutlet weak var refreshButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let navVC = self.navigationController as? SummaryNavigationController {
            self.persistentContainer = navVC.persistentContainer
            
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
            extractData()
        }
       
    }
    
    func extractData() {
        devices = recordController?.getDevices() ?? []
        
        for device in devices {
            
            guard let lowest = recordController?.lowestInternalTemp(forDevice: device),
                let lowDate = lowest.created_at else { return }
            let formatter = DateFormatter.HHmmss
            print("\(device.name!) lowest internal temp: \(lowest.internal_temp) degrees at \(formatter.string(from: lowDate))")
        }
        
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
    }
    
    func refresh() {
        recordController?.refreshRecordsForAllDevices {
            self.extractData()
            DispatchQueue.main.async() {
                
                self.refreshButton.isEnabled = true
                
            }
        }
    }
    
    @IBAction func buttonClickedRefresh(_ sender: Any) {
        refreshButton.isEnabled = false
        self.refresh()
        
    }
    
    @IBAction func buttonClickedSetup(_ sender: Any) {
        DispatchQueue.main.async(){
            self.performSegue(withIdentifier:self.AUTHORIZATION_SEGUE, sender: self)
        }
    }
    
    func failedAuthorization() {
         guard let authVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "AUTHORIZATION_VIEW_CONTROLLER") as? AuthorizationViewController else { return }
        authVC.reauthorization = true
        
        DispatchQueue.main.async() {
            self.present(authVC, animated: true, completion:  {
                self.refresh()
            })
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return devices.count > 0 ? devices.count + 1 : 0
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DEVICE_CELL") as! DeviceSummaryTableViewCell
        let externalSection = (indexPath.section == numberOfSections(in: tableView) - 1)
        
        if !externalSection {
            let device = devices[indexPath.row]
            guard let high = recordController?.highestInternalTemp(forDevice: device)?.internal_temp,
                let low = recordController?.lowestInternalTemp(forDevice: device)?.internal_temp,
                let current = recordController?.currentRecord(forDevice: device)?.internal_temp else { return cell }
            
            cell.setHigh(high)
            cell.setLow(low)
            cell.setCurrent(current)
        }
        else
        {
            let device = devices[0]
            guard let high = recordController?.highestInternalTemp(forDevice: device)?.external_temp,
                let low = recordController?.lowestInternalTemp(forDevice: device)?.external_temp,
                let current = recordController?.currentRecord(forDevice: device)?.external_temp else { return cell }
            
            cell.setHigh(Int(high))
            cell.setLow(Int(low))
            cell.setCurrent(Int(current))
        }

        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 88.0
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section < devices.count ? devices[section].name_long : "External"
    }

}

