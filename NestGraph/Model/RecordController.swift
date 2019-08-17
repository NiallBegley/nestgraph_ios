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

enum NetworkingErrorType {
    case noError
    case authError
    case networkError
}
protocol RecordControllerDelegate {
    func failedAuthorization()
    func failedNetworking()
}

class RecordController: NSObject {

    var persistentContainer: NSPersistentContainer?
    var delegate: RecordControllerDelegate?
    
    init(container: NSPersistentContainer) {
        self.persistentContainer = container
    }
    
    func deleteAll(entity: String) {
        
        guard let context = self.persistentContainer?.viewContext else {
            return
        }
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try context.execute(deleteRequest)
        } catch let error as NSError {
            // TODO: handle this error
        }
    }
    
    func deleteAll() {
        deleteAll(entity: "Device")
        deleteAll(entity: "Record")
        KeychainSwift().clear()
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
    
    func refreshRecordsFor(device: Device, completionHandler: @escaping (_ error: NetworkingErrorType) -> Void)
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
                    completionHandler(.networkError)
                    return
            }
            
            guard (200 ... 299) ~= response.statusCode else {                    // check for http errors
                print("statusCode should be 2xx, but is \(response.statusCode)")
                print("response = \(response)")
                
                if response.statusCode == 401
                {
                    print("Failed authorization")
                   completionHandler(.authError)
                }
                return
            }
            
            guard let records = self.parse(data, entity: [Record].self) else { return }
            
//            device.mutableSetValue(forKey: "records").addObjects(from: records)
            
            print("Fetched \(records.count) records for device \(device.name ?? "#DEVICE NAME NOT FOUND#")")
            
            completionHandler(.noError)
            
        }
        
        task.resume()
    }
    
    func refreshRecordsForAllDevices(completionHandler: @escaping () -> Void) {
        let group = DispatchGroup()
        let devices = getDevices()
        var errorType : NetworkingErrorType = .noError
        
        let handler: (_ error : NetworkingErrorType) -> Void = { (_ error : NetworkingErrorType) in
            errorType = error
            group.leave()
        }
        
        for device in devices {
            group.enter()
            refreshRecordsFor(device: device, completionHandler: handler)
        }
        
        //Prevent the failedAuthorization delegate call from being called 1 time for every Device
        group.notify(queue: DispatchQueue.global(qos: .background)) {
            switch(errorType) {
                case .authError:
                    self.delegate?.failedAuthorization()
                    break;
                
                case .networkError:
                    self.delegate?.failedNetworking()
                    break;
                
                default:
                    break;
                
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
            
            managedObjectContext.mergePolicy = NSMergePolicy(merge: .mergeByPropertyObjectTrumpMergePolicyType)
            
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
    
    func allRecords(forDevice device: Device, between startDate: Date, _ endDate: Date ) -> [Record]
    {
        guard let context = self.persistentContainer?.viewContext else {
            return []
        }
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Record")
        
        guard let device_id = device.device_id else { return [] }
        request.predicate = NSPredicate.init(format: "created_at > %@ AND created_at < %@ AND device_id == %@", startDate as NSDate, endDate as NSDate, device_id)
        
        
        request.sortDescriptors = [NSSortDescriptor.init(key: "created_at", ascending: true)]
        
        do {
            let result = try context.fetch(request)
            return result as! [Record]
        } catch {
            print("Failed all records fetch")
        }
        
        return []
    }
    
    func extremeValue(forKey key: String, device: Device, lowest: Bool ) -> Record? {
        guard let context = self.persistentContainer?.viewContext else {
            return nil
        }
        
        let today = Calendar.current
        guard let twelveHoursDate = today.date(byAdding: .hour, value: -24, to: Date(), wrappingComponents: false) else { return nil }
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Record")
        
        guard let device_id = device.device_id else { return nil }
        request.predicate = NSPredicate.init(format: "created_at > %@ AND device_id == %@", twelveHoursDate as NSDate, device_id)
        
        request.fetchLimit = 1
        request.sortDescriptors = [NSSortDescriptor.init(key: key, ascending: lowest)]
        
        do {
            let result = try context.fetch(request)
            
            if result.count == 1 {
                let lowestRecord = result.first as! Record
                return lowestRecord
            }
        } catch {
            
            print("Failed")
        }
        
        return nil
    }
    
    func currentRecord(forDevice device: Device) -> Record? {
        guard let context = self.persistentContainer?.viewContext else {
            return nil
        }
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Record")
        
        guard let device_id = device.device_id else { return nil }
        request.predicate = NSPredicate.init(format: "device_id == %@", device_id)
        
        request.fetchLimit = 1
        request.sortDescriptors = [NSSortDescriptor.init(key: "created_at", ascending: false)]
        
        do {
            let result = try context.fetch(request)
            print("Found \(result.count) records")
            
            if result.count == 1 {
                let currentRecord = result.first as! Record
                return currentRecord
            }
        } catch {
            
            print("Failed")
        }
        
        return nil
    }
    
    func lowestInternalTemp(forDevice device : Device) -> Record? {
        return extremeValue(forKey: "internal_temp", device: device, lowest: true)
    }
    
    func lowestExternalTemp(forDevice device : Device) -> Record? {
        return extremeValue(forKey: "external_temp", device: device, lowest: true)
    }
    
    func highestInternalTemp(forDevice device : Device) -> Record? {
        return extremeValue(forKey: "internal_temp", device: device, lowest: false)
    }
    
    func highestExternalTemp(forDevice device : Device) -> Record? {
        return extremeValue(forKey: "external_temp", device: device, lowest: false)
    }
}
