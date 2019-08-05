//
//  InstanceChooserViewController.swift
//  NestGraph
//
//  Created by Niall on 7/26/19.
//  Copyright © 2019 Niall. All rights reserved.
//

import UIKit
import CoreData
import KeychainSwift

class InstanceChooserViewController: UIViewController {

    @IBOutlet weak var urlField: UITextField!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var verifyButton: UIButton!
    let VERIFY_URL_SEGUE = "VERIFY_URL_SEGUE"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if KeychainSwift().getHost() != nil
        {
            DispatchQueue.main.async(){
                self.performSegue(withIdentifier:self.VERIFY_URL_SEGUE, sender: self)
            }
        }
    }
    
    @IBAction func buttonClickedVerify(_ sender: Any) {
        
        guard let urlString = urlField.text, !urlString.isEmpty else {
            return
        }
        
        toggleIndicator()
        
        let url = URL(string: urlString)!
        let request = URLRequest(url: url)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let httpResponse = response as? HTTPURLResponse, error == nil else {
                    self.showError()
                    return
            }
            
            if (200 ... 299).contains(httpResponse.statusCode)
            {
                KeychainSwift().setHost(value: urlString)
                DispatchQueue.main.async(){
                    self.toggleIndicator()
                    self.performSegue(withIdentifier:self.VERIFY_URL_SEGUE, sender: self)
                }
            }
            else
            {
                self.showError()
            }
        }
        
        task.resume()
        
        
    }
    
    func showError() {
        
        DispatchQueue.main.async(){
            self.toggleIndicator()
            self.errorLabel.isHidden = false
        }
    }

    func toggleIndicator()
    {
        errorLabel.isHidden = true
        activityIndicator.isHidden = !activityIndicator.isHidden
        activityIndicator.isHidden ? activityIndicator.stopAnimating() : activityIndicator.startAnimating()
        
        verifyButton.isHidden = !verifyButton.isHidden
    }
}
