//
//  SetupProgressCellTableViewCell.swift
//  NestGraph
//
//  Created by Niall on 7/30/19.
//  Copyright © 2019 Niall. All rights reserved.
//

import UIKit

class SetupProgressCellTableViewCell: UITableViewCell {
    @IBOutlet weak var progressIndicator: UIActivityIndicatorView!
    @IBOutlet weak var label: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
}
