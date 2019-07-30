//
//  Device.swift
//  NestGraph
//
//  Created by Niall on 7/25/19.
//  Copyright © 2019 Niall. All rights reserved.
//

import UIKit
import CoreData

class Device:  NSManagedObject, Codable {

    enum CodingKeys: String, CodingKey {
        case device_id
        case name
        case name_long
        case can_heat
        case can_cool
    }
    
    @NSManaged var device_id: String?
    @NSManaged var name: String?
    @NSManaged var name_long: String?
    @NSManaged var can_heat: Bool
    @NSManaged var can_cool: Bool
    
    required convenience init(from decoder: Decoder) throws {

        guard let codingUserInfoKeyManagedObjectContext = CodingUserInfoKey.managedObjectContext,
            let managedObjectContext = decoder.userInfo[codingUserInfoKeyManagedObjectContext] as? NSManagedObjectContext,
            let entity = NSEntityDescription.entity(forEntityName: "Device", in: managedObjectContext) else {
                fatalError("Failed to decode Device")
        }

        self.init(entity: entity, insertInto: managedObjectContext)

        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.device_id = try container.decodeIfPresent(String.self, forKey: .device_id)
        self.name = try container.decodeIfPresent(String.self, forKey: .name)
        self.name_long = try container.decodeIfPresent(String.self, forKey: .name_long)
        self.can_heat = try container.decodeIfPresent(Bool.self, forKey: .can_heat) ?? false
        self.can_cool = try container.decodeIfPresent(Bool.self, forKey: .can_cool) ?? false
    }

    // MARK: - Encodable
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(device_id, forKey: .device_id)
        try container.encode(name, forKey: .name)
        try container.encode(name_long, forKey: .name_long)
        try container.encode(can_heat, forKey: .can_heat)
        try container.encode(can_cool, forKey: .can_cool)
    }

    
}
