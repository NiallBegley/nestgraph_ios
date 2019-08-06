//
//  FirstTimeDataViewController.swift
//  NestGraph
//
//  Created by Niall on 7/28/19.
//  Copyright © 2019 Niall. All rights reserved.
//

import UIKit
import CoreData
import KeychainSwift

struct ProgressStep {
    let text : NSString?
    var animating : Bool
    var done : Bool
    
    init(text: NSString, animating: Bool, done: Bool) {
        self.text = text
        self.animating = animating
        self.done = done
    }
}

class FirstTimeDataViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, RecordControllerDelegate {
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var doneButton: UIButton!
    var persistentContainer: NSPersistentContainer?
    var progressSteps: [ProgressStep] = []
    private var recordController : RecordController?
    
    override func viewDidAppear(_ animated: Bool) {
        
        guard let host = KeychainSwift().getHost(),
            let url = URL(string: host + "/devices/api_endpoint.json") else {
                print("Error forming URL for devices endpoint")
                return
        }
        
        var request = URLRequest(url: url)
        request.setValue(KeychainSwift().getAuthToken(), forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        
        //TODO: Needs to handle failures
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                let response = response as? HTTPURLResponse,
                error == nil else {                                              // check for fundamental networking error
                    print("error", error ?? "Unknown error")
                    return
            }
            
            guard (200 ... 299) ~= response.statusCode else {                    // check for http errors
                print("statusCode should be 2xx, but is \(response.statusCode)")
                print("response = \(response)")
                return
            }
            
            let responseString = String(data: data, encoding: .utf8)
            print("responseString = \(responseString)")
            
            guard let devices = self.recordController?.parse(data, entity: [Device].self) else { return }
            
            print("Found \(devices.count) devices")
            
            DispatchQueue.main.async() {
                let stepText = NSString(format: "Found %d Nest devices", devices.count)
                self.progressSteps[self.progressSteps.count-1].done = true
                self.progressSteps.append(ProgressStep.init(text: stepText, animating: false, done: true))
                
                
                self.progressSteps.append(ProgressStep.init(text: "Fetching records for devices", animating: true, done: false))
                self.tableView.reloadData()
            }
            
            self.recordController?.refreshRecordsForAllDevices {
                DispatchQueue.main.async() {
                    self.progressSteps[self.progressSteps.count-1].done = true
                    self.tableView.reloadData()
                    
                    self.doneButton.isHidden = false
                }
            }
        }
        
        task.resume()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let navVC = self.navigationController as? SetupViewController {
            self.persistentContainer = navVC.persistentContainer
            
            if self.persistentContainer != nil
            {
                self.recordController = RecordController.init(container: self.persistentContainer!)
                self.recordController?.delegate = self
            }
        }
        
        progressSteps.append(ProgressStep.init(text: "Fetching list of Nest devices", animating: true, done: false))
        tableView.reloadData()
    }
    
    @IBAction func onButtonDone(_ sender: Any) {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return progressSteps.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "PROGRESS_CELL") as! SetupProgressCellTableViewCell
        
        cell.label?.text = progressSteps[indexPath.row].text as String?
        cell.progressIndicator?.isHidden = progressSteps[indexPath.row].done
        progressSteps[indexPath.row].animating ? cell.progressIndicator?.startAnimating() : cell.progressIndicator?.stopAnimating()
        cell.accessoryType = progressSteps[indexPath.row].done ? .checkmark : .none
        
//        cell.accessoryType = .checkmark
        return cell
    }
    
    func failedAuthorization() {
        self.navigationController?.popViewController(animated: true)
    }
    
}
