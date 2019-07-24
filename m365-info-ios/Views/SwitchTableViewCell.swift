//
//  SwitchTableViewCell.swift
//  m365-info-ios
//
//  Created by Michał Jach on 15/07/2019.
//  Copyright © 2019 Michał Jach. All rights reserved.
//

import UIKit

class SwitchTableViewCell: UITableViewCell {
    var closure: ((Bool) -> Void)?
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var `switch`: UISwitch!
    
    @IBAction func switched(_ sender: UISwitch) {
        closure!(sender.isOn)
    }
}
