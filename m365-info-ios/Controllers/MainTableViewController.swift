//
//  MainTableViewController.swift
//  m365-info-ios
//
//  Created by Michał Jach on 11/07/2019.
//  Copyright © 2019 Michał Jach. All rights reserved.
//

import UIKit

class MainTableViewController: UITableViewController {
    var m365: M365Info?
    var data: [String: String] = [:]
    var map = [
        "Serial Number",
        "Firmware Version",
        "Battery Level",
        "Body Temperature",
        "Total Mileage",
        "Voltage",
        "Current Speed",
        "Tail Led",
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        m365?.dataDelegate = self
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return map.count
        } else {
            return 1
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Scooter info"
        } else {
            return "Manage firmware"
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "detailsCell", for: indexPath) as! DetailsTableViewCell
            cell.titleLabel.text = "Firmware"
            
            return cell
        } else {
            if indexPath.row == 7 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "switchCell", for: indexPath) as! SwitchTableViewCell
                cell.titleLabel.text = map[indexPath.row]
                cell.closure = { isOn in
                    if isOn {
                        self.m365?.turnOnLed()
                    } else {
                        self.m365?.turnOffLed()
                    }
                }
                
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! MainTableViewCell
                cell.titleLabel.text = map[indexPath.row]
                cell.valueLabel.text = data[map[indexPath.row]]
                
                return cell
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let viewController = segue.destination as? FlashViewController {
            viewController.m365info = m365
        }
    }
}

extension MainTableViewController: M365DataDelegate {
    func didUpdateValues(values: [String : String]) {
        data = values
        tableView.reloadData()
    }
}
