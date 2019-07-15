//
//  DevicesTableViewController.swift
//  m365-info-ios
//
//  Created by Michał Jach on 12/07/2019.
//  Copyright © 2019 Michał Jach. All rights reserved.
//

import UIKit
import CoreBluetooth

class DevicesTableViewController: UITableViewController {
    var m365: M365Info?
    var devices: [CBPeripheral] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        m365 = M365Info.init()
        m365?.devicesDelegate = self
        m365?.stateDelegate = self
        
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return devices.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "deviceCell", for: indexPath) as UITableViewCell
        
        cell.textLabel?.text = devices[indexPath.row].name
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        m365?.connect(device: devices[indexPath.row])
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let viewController = segue.destination as? MainTableViewController {
            viewController.m365 = m365
        }
    }
}

extension DevicesTableViewController: M365StateDelegate {
    func didChangeState(state: CBManagerState) {
        if state == .poweredOn {
            m365?.discover()
        }
    }
}

extension DevicesTableViewController: M365DevicesDelegate {
    func didDiscoverDevice(peripheral: CBPeripheral) {
        devices.append(peripheral)
        tableView.reloadData()
    }
    
    func didConnect(peripheral: CBPeripheral) {
        
    }
}
