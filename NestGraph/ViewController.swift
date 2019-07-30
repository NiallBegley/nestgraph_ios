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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
//        if UserDefaults.standard.getAuthToken() == nil {
//            print("No auth token detected")
        
            DispatchQueue.main.async(){
                self.performSegue(withIdentifier:self.AUTHORIZATION_SEGUE, sender: self)
            }
            
//        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == AUTHORIZATION_SEGUE
        {
            if let vc = segue.destination as? SetupViewController {
                vc.persistentContainer = persistentContainer
            }
        }
    }
    
}

