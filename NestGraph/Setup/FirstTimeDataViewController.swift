//
//  FirstTimeDataViewController.swift
//  NestGraph
//
//  Created by Niall on 7/28/19.
//  Copyright © 2019 Niall. All rights reserved.
//

import UIKit
import CoreData

class FirstTimeDataViewController: UIViewController {

    var persistentContainer: NSPersistentContainer?

    override func viewDidLoad() {
        super.viewDidLoad()

        if let navVC = self.navigationController as? SetupViewController {
            self.persistentContainer = navVC.persistentContainer
        }
        
        let url = URL(string: "http://localhost:3000/devices/api_endpoint.json")!
        
        var request = URLRequest(url: url)
        request.setValue(UserDefaults.standard.getAuthToken(), forHTTPHeaderField: "Authorization")
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
            
            guard let devices = self.parse(data, entity: [Device].self) else { return }
            for device in devices {
                self.fetchRecordsFor(device: device)
            }
            
            
  
           
        }
        
        task.resume()
    }

}

extension FirstTimeDataViewController {
    func fetchRecordsFor(device: Device)
    {
        let url = URL(string: "http://localhost:3000/records/api_endpoint.json")!
        
        var request = URLRequest(url: url)
        request.setValue(UserDefaults.standard.getAuthToken(), forHTTPHeaderField: "Authorization")
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
            
            guard let records = self.parse(data, entity: [Record].self) else { return }
            
            
            
            
        }
        
        task.resume()
    }
    
    
    func parse<T: Decodable> (_ jsonData: Data, entity: T.Type) -> T? {
        do {
            guard let codingUserInfoKeyManagedObjectContext = CodingUserInfoKey.managedObjectContext else {
                fatalError("Failed to retrieve context")
            }
            
            // Parse JSON data
            guard let managedObjectContext = persistentContainer?.viewContext else {
                return nil
            }
          
            let decoder = JSONDecoder()
            decoder.userInfo[codingUserInfoKeyManagedObjectContext] = managedObjectContext
            let entities = try decoder.decode(entity, from: jsonData)
            try managedObjectContext.save()
            
            return entities
        } catch let error {
            print(error)
            return nil
        }
    }
    
}
