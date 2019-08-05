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

class ViewController: UIViewController, URLSessionTaskDelegate, RecordControllerDelegate{
   
    var authorization: String?
    var persistentContainer: NSPersistentContainer?
    let AUTHORIZATION_SEGUE = "AUTHORIZATION_SEGUE"
    var recordController : RecordController?
    
    private var showingSetup = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if persistentContainer != nil {
            recordController = RecordController.init(container: persistentContainer!)
            recordController?.delegate = self
        } else {
            fatalError()
        }
        
       
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if KeychainSwift().getAuthToken() == nil
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
    
    func refresh() {
        recordController?.fetchRecordsForAllDevices {
            self.extractData()
        }
    }
    
    @IBAction func buttonClickedRefresh(_ sender: Any) {
       self.refresh()
        
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
    

}

