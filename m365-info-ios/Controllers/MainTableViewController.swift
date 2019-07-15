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
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        m365?.dataDelegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        m365?.disconnect()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! MainTableViewCell
        
        cell.titleLabel.text = map[indexPath.row]
        cell.valueLabel.text = data[map[indexPath.row]]
        
        return cell
    }
}

extension MainTableViewController: M365DataDelegate {
    func didUpdateValues(values: [String : String]) {
        data = values
        tableView.reloadData()
    }
}
