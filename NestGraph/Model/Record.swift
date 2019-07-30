//
//  Record.swift
//  NestGraph
//
//  Created by Niall on 7/29/19.
//  Copyright © 2019 Niall. All rights reserved.
//

import UIKit
import CoreData

class Record:  NSManagedObject, Codable {
    
    enum CodingKeys: String, CodingKey {
        case device_id
        case internal_temp
        case external_temp
        case target_temp
        case created_at
        case humidity
        case timeToTarget = "time_to_target"
        case external_humidity
        case is_heating
    }
    
    @NSManaged var device_id : String?
    @NSManaged var  internal_temp : Int
    @NSManaged var  external_temp : Float
    @NSManaged var  target_temp : Int
    @NSManaged var  created_at : Date?
    @NSManaged var  humidity : Int
    @NSManaged var  timeToTarget : String?
    @NSManaged var  external_humidity : Int
    @NSManaged var  is_heating : Int
    
    required convenience init(from decoder: Decoder) throws {
        
        guard let codingUserInfoKeyManagedObjectContext = CodingUserInfoKey.managedObjectContext,
            let managedObjectContext = decoder.userInfo[codingUserInfoKeyManagedObjectContext] as? NSManagedObjectContext,
            let entity = NSEntityDescription.entity(forEntityName: "Device", in: managedObjectContext) else {
                fatalError("Failed to decode Device")
        }
        
        self.init(entity: entity, insertInto: managedObjectContext)
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.device_id = try container.decodeIfPresent(String.self, forKey: .device_id)
        self.internal_temp = try container.decodeIfPresent(Int.self, forKey: .internal_temp) ?? 0
        self.external_temp = try container.decodeIfPresent(Float.self, forKey: .external_temp) ?? 0.0
        self.target_temp = try container.decodeIfPresent(Int.self, forKey: .target_temp) ?? 0
        self.created_at = try container.decodeIfPresent(Date.self, forKey: .created_at)
        self.humidity = try container.decodeIfPresent(Int.self, forKey: .humidity) ?? 0
        self.timeToTarget = try container.decodeIfPresent(String.self, forKey: .timeToTarget)
        self.external_humidity = try container.decodeIfPresent(Int.self, forKey: .external_humidity) ?? 0
        self.is_heating = try container.decodeIfPresent(Int.self, forKey: .is_heating) ?? 0
        
        
    }
    
    // MARK: - Encodable
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(device_id, forKey: .device_id)
    }
    
    
}
