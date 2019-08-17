//
//  DeviceSummaryTableViewCell.swift
//  NestGraph
//
//  Created by Niall on 8/11/19.
//  Copyright © 2019 Niall. All rights reserved.
//

import UIKit
import ChameleonFramework

class DeviceSummaryTableViewCell: UITableViewCell {

    
    @IBOutlet weak var labelConstraint: NSLayoutConstraint!
    @IBOutlet weak var currentLabel: UILabel!
    @IBOutlet weak var lowLabel: UILabel!
    @IBOutlet weak var highLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        lowLabel.textColor = UIColor.flatSkyBlue
        highLabel.textColor = UIColor.flatRed
    }

    override func draw(_ rect: CGRect) {
        let bounds = currentLabel.layer.bounds
        currentLabel.layer.cornerRadius = bounds.size.width * 0.5
        currentLabel.layer.borderWidth = 0
        currentLabel.layer.backgroundColor = UIColor.black.cgColor
        currentLabel.layer.borderColor = UIColor.black.cgColor
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    
    func setHigh(_ temp: Int)
    {
        highLabel.text = String(format: "%d", temp)
    }
    
    func setLow(_ temp: Int)
    {
        lowLabel.text = String(format: "%d", temp)
    }
    
    func setCurrent(_ temp: Int)
    {
        currentLabel.text = String(format: "%d", temp)
    }
    
    
}
