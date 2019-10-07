//
//  AuthorizationViewController.swift
//  NestGraph
//
//  Created by Niall on 7/15/19.
//  Copyright © 2019 Niall. All rights reserved.
//

import UIKit
import CoreData
import KeychainSwift

class AuthorizationViewController: UIViewController, URLSessionTaskDelegate, UITextFieldDelegate{
    
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var reauthorizeLabel: UILabel!
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var signInButton: UIButton!
    let FIRST_TIME_DATA_SEGUE = "FIRST_TIME_DATA_SEGUE"
    var reauthorization = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        reauthorizeLabel.isHidden = !reauthorization
        

#if DEBUG
        usernameField.text = ProcessInfo.processInfo.environment["USERNAME"]
        passwordField.text = ProcessInfo.processInfo.environment["PASSWORD"]
#endif
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
    
    func showErrorLabel(_ show: Bool, withError: String?)
    {
        DispatchQueue.main.async(){
            self.signInButton.isEnabled = true
            self.errorLabel.isHidden = !show
            self.errorLabel.text = withError
        }
    }
    
    @IBAction func buttonClickedSignIn(_ sender: Any) {
        
        signInButton.isEnabled = false
        passwordField.resignFirstResponder()
        usernameField.resignFirstResponder()
        
        guard let host = KeychainSwift().getHost(),
            let url = URL(string: host + "/users/login") else
        {
            print("Error forming sign in URL")
            showErrorLabel(true, withError: "Error forming sign in URL - please check instance URL")
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
        
        let task = session.dataTask(with: request) { data, response, error in
            guard let response = response as? HTTPURLResponse,
                error == nil else {
                    
                    self.showErrorLabel(true, withError: "Networking error - please check connection")
                    return
            }
            
            guard (200 ... 299) ~= response.statusCode else {                  
                if response.statusCode == 401 {
                    self.showErrorLabel(true, withError: "Authorization error - please check username/password")
                } else {
                    self.showErrorLabel(true, withError: "Unspecified error connecting to server")
                }
                return
            }
            
            if let authtoken = response.allHeaderFields["Authorization"] as? String
            {
                KeychainSwift().setAuthToken(value: authtoken )
                
                DispatchQueue.main.async(){
                    if !self.reauthorization
                    {
                        self.performSegue(withIdentifier: self.FIRST_TIME_DATA_SEGUE, sender: nil)
                    }
                    else
                    {
                        self.dismiss(animated: true, completion: nil)
                    }
                }
            }
            else {
                DispatchQueue.main.async() {
                    self.showErrorLabel(true, withError: "Authorization error - please check username/password")
                    
                }
            }
        }
        
        task.resume()
        
    }
    
    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping (URLRequest?) -> Void)
    {
        print(response.allHeaderFields)
        if let authtoken = response.allHeaderFields["Authorization"] as? String
        {
            KeychainSwift().setAuthToken(value: authtoken )
            
            DispatchQueue.main.async(){
                if !self.reauthorization
                {
                    self.performSegue(withIdentifier: self.FIRST_TIME_DATA_SEGUE, sender: nil)
                }
                else
                {
                    self.dismiss(animated: true, completion: nil)
                }
            }
        }
        else {
            DispatchQueue.main.async() {
                self.showErrorLabel(true, withError: "Authorization error - please check username/password")
                
            }
        }
    }
    
}
