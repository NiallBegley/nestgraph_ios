//
//  UserDefaults.swift
//  NestGraph
//
//  Created by Niall on 7/24/19.
//  Copyright © 2019 Niall. All rights reserved.
//

import UIKit

extension UserDefaults {

    enum UserDefaultsKeys : String {
        case authtoken
        case host
    }
    
    func setAuthToken(value: String)
    {
        set(value, forKey:UserDefaultsKeys.authtoken.rawValue)
    }
    
    func getAuthToken() -> String? {
        return string(forKey: UserDefaultsKeys.authtoken.rawValue)
    }
    
    func setHost(value: String)
    {
        set(value, forKey:UserDefaultsKeys.host.rawValue)
    }
    
    func getHost() -> String? {
        return string(forKey: UserDefaultsKeys.host.rawValue)
    }
    
}
