//
//  CodingUserInfoKey+Util.swift
//  NestGraph
//
//  Created by Niall on 7/29/19.
//  Copyright © 2019 Niall. All rights reserved.
//

import Foundation

public extension CodingUserInfoKey {
    // Helper property to retrieve the Core Data managed object context
    static let managedObjectContext = CodingUserInfoKey(rawValue: "managedObjectContext")
}
