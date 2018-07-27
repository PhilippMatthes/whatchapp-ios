//
//  ViewController.swift
//  whatchapp
//
//  Created by Philipp Matthes on 22.07.18.
//  Copyright © 2018 Philipp Matthes. All rights reserved.
//

import UIKit
import WebKit
import Material
import WatchConnectivity

class ViewController: TableViewController {
    
    var lastUpdate = Storage.lastUpdate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(TableViewCell.self, forCellReuseIdentifier: "TableViewCell")
        tableView.layoutMargins = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 4)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return lastUpdate?.chats.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 4.0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = UIColor.clear
        return headerView
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "TableViewCell") as? TableViewCell else {return UITableViewCell()}
        let chat = lastUpdate!.chats[indexPath.section]
        cell.textLabel?.text = "\(chat.name) (\(chat.date))"
        cell.detailTextLabel?.text = chat.message
        cell.textLabel?.textColor = .white
        cell.detailTextLabel?.textColor = .white
        cell.textLabel?.numberOfLines = 0
        cell.detailTextLabel?.numberOfLines = 0
        cell.layer.cornerRadius = 10.0
        cell.backgroundColor = UIColor(rgb: 0x2ECC71)
        return cell
    }
    
}

