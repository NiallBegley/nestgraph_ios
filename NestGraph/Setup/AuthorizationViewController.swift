//
//  AuthorizationViewController.swift
//  NestGraph
//
//  Created by Niall on 7/15/19.
//  Copyright © 2019 Niall. All rights reserved.
//

import UIKit
import CoreData

class AuthorizationViewController: UIViewController, URLSessionTaskDelegate, UITextFieldDelegate{

    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var signInButton: UIButton!
    let FIRST_TIME_DATA_SEGUE = "FIRST_TIME_DATA_SEGUE"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if UserDefaults.standard.getAuthToken() != nil
        {
            DispatchQueue.main.async(){
                self.performSegue(withIdentifier:self.FIRST_TIME_DATA_SEGUE, sender: self)
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == usernameField
        {
            passwordField.becomeFirstResponder()
        }
        else
        {
            passwordField.resignFirstResponder()
        }
        
        return false
    }
    
    @IBAction func buttonClickedSignIn(_ sender: Any) {
        
        signInButton.isEnabled = false
        passwordField.resignFirstResponder()
        usernameField.resignFirstResponder()
        
        //TODO: Needs to be stored / asked for somewhere
        guard let host = UserDefaults.standard.getHost(),
            let url = URL(string: host + "/users/sign_in") else
        {
            print("Error forming sign in URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        let json: [String: Any] = [
            "user": ["email": usernameField.text, "password":passwordField.text]]
        
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        
        request.httpBody = jsonData
        
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        
        //TODO: Needs to handle failures
        let task = session.dataTask(with: request) { data, response, error in
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
            
            if let headerFiles = response.allHeaderFields as? [String: String] {
                print(headerFiles)
                
            }
            let responseString = String(data: data, encoding: .utf8)
            print("responseString = \(responseString)")
        }
        
        task.resume()
        
    }
    
    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping (URLRequest?) -> Void)
    {
        //TODO: Needs to handle failures / missing Authorization header
        print(response.allHeaderFields)
        if let authtoken = response.allHeaderFields["Authorization"] as? String
        {
            //TODO: This needs to be stored in the keychain
            UserDefaults.standard.setAuthToken(value: authtoken )
            
            DispatchQueue.main.async(){
                self.performSegue(withIdentifier: self.FIRST_TIME_DATA_SEGUE, sender: nil)
            }
        }
    }
    
}
