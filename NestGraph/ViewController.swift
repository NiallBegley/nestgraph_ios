//
//  ViewController.swift
//  NestGraph
//
//  Created by Niall on 7/15/19.
//  Copyright © 2019 Niall. All rights reserved.
//


import UIKit
import CoreData

class ViewController: UIViewController, URLSessionTaskDelegate{

    var authorization: String?
    var persistentContainer: NSPersistentContainer?
    let AUTHORIZATION_SEGUE = "AUTHORIZATION_SEGUE"
    var recordController : RecordController?
    
    private var showingSetup = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if persistentContainer != nil {
            recordController = RecordController.init(container: persistentContainer!)
        } else {
            fatalError()
        }
        
       
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if UserDefaults.standard.getAuthToken() == nil
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
        guard let devices = recordController?.getDevices() else { return }
        
        for device in devices {
            let records = device.mutableSetValue(forKey: "records")
            print("Found \(records.count) records for device")
            
            guard let lowest = recordController?.lowestTemp(forDevice: device),
                let lowDate = lowest.created_at else { return }
            let formatter = DateFormatter.HHmmss
            print("\(device.name) lowest internal temp: \(lowest.internal_temp) degrees at \(formatter.string(from: lowDate))")
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
    
    @IBAction func buttonClickedRefresh(_ sender: Any) {
        guard let devices = recordController?.getDevices() else { return }
        let handler: () -> Void = {
            self.extractData()
        }
        for (index, device) in devices.enumerated() {
            recordController?.fetchRecordsFor(device: device, completionHandler: index == devices.count - 1 ? handler : { () -> Void in return})
        }
        
    }
}

