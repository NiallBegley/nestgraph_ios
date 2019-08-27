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
    }
    
    func showErrorLabel(_ show: Bool, withError: String?)
    {
        DispatchQueue.main.async(){
            self.toggleIndicator()
            self.errorLabel.isHidden = !show
            self.errorLabel.text = withError
        }
    }
    
    @IBAction func buttonClickedVerify(_ sender: Any) {
        
        toggleIndicator()
        
        guard let urlString = urlField.text, !urlString.isEmpty else {
            self.showErrorLabel(true, withError: "Missing URL")
            return
        }
        
        let url = URL(string: urlString)!
        let request = URLRequest(url: url)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let httpResponse = response as? HTTPURLResponse, error == nil else {
                self.showErrorLabel(true, withError: "Networking error - please check device settings")
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
                self.showErrorLabel(true, withError: "Received invalid HTTP response - verify URL")
            }
        }
        
        task.resume()
        
        
    }

    func toggleIndicator()
    {
        errorLabel.isHidden = true
        activityIndicator.isHidden = !activityIndicator.isHidden
        activityIndicator.isHidden ? activityIndicator.stopAnimating() : activityIndicator.startAnimating()
        
        verifyButton.isHidden = !verifyButton.isHidden
    }
}
