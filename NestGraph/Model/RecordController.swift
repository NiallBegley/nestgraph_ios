//
//  RecordController.swift
//  NestGraph
//
//  Created by Niall on 8/1/19.
//  Copyright © 2019 Niall. All rights reserved.
//

import UIKit
import CoreData
import KeychainSwift

protocol RecordControllerDelegate {
    func failedAuthorization()
}

class RecordController: NSObject {

    var persistentContainer: NSPersistentContainer?
    var delegate: RecordControllerDelegate?
    
    init(container: NSPersistentContainer) {
        self.persistentContainer = container
    }
    
    func getDevices() -> [Device] {
        guard let context = self.persistentContainer?.viewContext else {
            return []
        }
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Device")
        
        do {
            let result = try context.fetch(request)
            print("Found \(result.count) devices")
            
            return result as! [Device]
        } catch {
            
            print("Failed")
        }
        
        return []
    }
    
    func fetchRecordsFor(device: Device, completionHandler: @escaping (_ authError: Bool) -> Void)
    {
        print("Fetching records for device \(device.name ?? "#NAME NOT FOUND#")...")
        
        guard let host = KeychainSwift().getHost(),
            var url = URLComponents(string: host + "/records/api_endpoint.json") else
        {
            print("Error forming records endpoint URL")
            return
        }
        
        let today = Calendar.current
        guard let twoDaysDate = today.date(byAdding: .day, value: -2, to: Date(), wrappingComponents: false) else { return }
        let todayDate = Date()
        //        let twoDaysAgo = String((describing: calDate)
        
        let dateFormatter = DateFormatter.MMMdcyyyy
        let queryStart = dateFormatter.string(from: twoDaysDate)
        let queryEnd = dateFormatter.string(from: todayDate)
        
        url.queryItems = [
            URLQueryItem(name: "device_id", value: device.device_id),
            URLQueryItem(name: "start", value: queryStart),
            URLQueryItem(name: "end", value: queryEnd)
        ]
        
        var request = URLRequest(url: url.url!)
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
                
                if response.statusCode == 401
                {
                    print("Failed authorization")
                   completionHandler(true)
                }
                return
            }
            
            guard let records = self.parse(data, entity: [Record].self) else { return }
            
            device.mutableSetValue(forKey: "records").addObjects(from: records)
            
            print("Fetched \(records.count) records for device \(device.name ?? "#DEVICE NAME NOT FOUND#")")
            
            completionHandler(false)
            
        }
        
        task.resume()
    }
    
    func fetchRecordsForAllDevices(completionHandler: @escaping () -> Void) {
        let group = DispatchGroup()
        let devices = getDevices()
        var error = false
        
        let handler: (_ authError : Bool) -> Void = { (_ authError : Bool) in
            error = authError
            group.leave()
        }
        
        for device in devices {
            group.enter()
            fetchRecordsFor(device: device, completionHandler: handler)
        }
        
        //Prevent the failedAuthorization delegate call from being called 1 time for every Device
        group.notify(queue: DispatchQueue.global(qos: .background)) {
            if error {
                self.delegate?.failedAuthorization()
            }
            
            completionHandler()
        }
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
            
            managedObjectContext.mergePolicy = NSMergePolicy(merge: .overwriteMergePolicyType)
            
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
    
    func lowestTemp(forDevice device : Device) -> Record? {
        guard let context = self.persistentContainer?.viewContext else {
            return nil
        }
        
        let today = Calendar.current
        guard let twelveHoursDate = today.date(byAdding: .hour, value: -12, to: Date(), wrappingComponents: false) else { return nil }
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Record")
        request.predicate = NSPredicate.init(format: "created_at > %@ AND device_id == %@", twelveHoursDate as NSDate, device.device_id!)
        
        request.fetchLimit = 1
        request.sortDescriptors = [NSSortDescriptor.init(key: "internal_temp", ascending: true)]
        
        do {
            let result = try context.fetch(request)
            print("Found \(result.count) records")
            
            if result.count == 1 {
                let lowestRecord = result.first as! Record
                return lowestRecord
            }
            
            print("Didn't find any results for low temp / records in last 12 hours")
        } catch {
            
            print("Failed")
        }
        
        return nil
    }
    
    func fetchRecords() -> [Record]?
    {
        guard let context = self.persistentContainer?.viewContext else {
            return []
        }
        
        let today = Calendar.current
        guard let twelveHoursDate = today.date(byAdding: .hour, value: -12, to: Date(), wrappingComponents: false) else { return [] }
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Record")
        request.predicate = NSPredicate.init(format: "created_at > %@", twelveHoursDate as NSDate)
        
        do {
            let result = try context.fetch(request)
            print("Found \(result.count) records")
            
            return result as? [Record]
        } catch {
            
            print("Failed")
            return []
        }
        
        
    }
}
