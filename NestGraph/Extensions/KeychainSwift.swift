//
//  UserDefaults.swift
//  NestGraph
//
//  Created by Niall on 7/24/19.
//  Copyright © 2019 Niall. All rights reserved.
//

import UIKit
import KeychainSwift

extension KeychainSwift {

    enum KeychainKeys : String {
        case authtoken
        case host
    }
    
    func setAuthToken(value: String)
    {
        set(value, forKey: KeychainKeys.authtoken.rawValue)
    }
    
    func getAuthToken() -> String? {
        return get(KeychainKeys.authtoken.rawValue)
    }
    
    func setHost(value: String)
    {
        set(value, forKey:KeychainKeys.host.rawValue)
    }
    
    func getHost() -> String? {
        return get(KeychainKeys.host.rawValue)
    }
    
}
