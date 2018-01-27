//
//  MainTableViewController.swift
//  USPS Tracking
//
//  Created by Faiz Surani on 1/20/18.
//  Copyright © 2018 Faiz Surani. All rights reserved.
//

import UIKit
import FoldingCell
import Floaty

class MainTableViewController: UITableViewController {

    let closedCellHeight: CGFloat = 180
    let openedCellHeight: CGFloat = 482
    var cellHeights: [CGFloat] = []
    
    var trackingInfoInTable = [TrackingInfo]()
    var trackingNumbersInTable = ["9400115901472857042449", "9400111699000478356043", "9361289711090102237076"]
    
    var storedTrackingData: [StoredTrackingData] {
        get {
            if let storedData = UserDefaults.standard.object(forKey: "storedTrackingData") {
                return storedData as! [StoredTrackingData]
            }
            return [StoredTrackingData]()
        }
        set {
            UserDefaults.standard.set(storedTrackingData, forKey: "storedTrackingData")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    

    private func setup() {
        menuButtonSetup()
        cellHeights = Array(repeating: closedCellHeight, count: trackingNumbersInTable.count)
        tableView.estimatedRowHeight = closedCellHeight
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.backgroundColor = UIColor(patternImage: #imageLiteral(resourceName: "Blurred Blue"))
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshTable), for: .valueChanged)
        tableView.refreshControl = refreshControl
        refreshTable()
    }
    
    private func menuButtonSetup() {
        Floaty.global.button.buttonImage = #imageLiteral(resourceName: "Menu Icon")
        Floaty.global.button.addItem("Add Tracking", icon: #imageLiteral(resourceName: "Add Icon")) { floatyItem in
            print("test")
        }
        Floaty.global.button.addItem("Scan Barcode", icon: #imageLiteral(resourceName: "Scan Barcode Icon")) { floatyItem in
            
        }
        Floaty.global.button.rotationDegrees = 90
        Floaty.global.show()
    }
    
    @objc public func refreshTable() {
        for i in 0 ..< trackingNumbersInTable.count {
            let tracker = USPS()
            tracker.getTrackingInfo(trackingNumbersInTable[i]) { trackingInfo, error in
                if error != nil {
                    print("Error: Refresh Failed On Row " + String(i))
                }
                else { DispatchQueue.main.async {
                    if i >= self.trackingInfoInTable.count {
                        self.trackingInfoInTable.append(trackingInfo!)
                    }
                    else {
                        self.trackingInfoInTable[i] = trackingInfo!
                    }
                    self.updateCell(self.tableView.cellForRow(at: IndexPath(row: i, section: 0)) as! TrackingInfoCell, trackingInfo!, row: i)
                    }
                }
            }
            
        }
        tableView.refreshControl?.endRefreshing()
    }
    
    public func setCells() {
        for i in 0 ..< storedTrackingData.count {
            let cell = tableView.cellForRow(at: IndexPath(row: i, section: 0)) as! TrackingInfoCell
            cell.closedCellTitle.text = storedTrackingData[i].name
            cell.openCellTitle.text = storedTrackingData[i].name
            cell.trackingNumberButton.setTitle(storedTrackingData[i].trackingNumber, for: .normal)
            cell.closedStatusUpdate.text = storedTrackingData[i].recentUpdate
        }
    }
    
    public func updateCell(_ cell: TrackingInfoCell, _ trackingInfo: TrackingInfo, row: Int) {
        let mostRecentStatus = trackingInfo.trackingUpdates[0]
        
        let daysUntilValue = daysUntil(trackingInfo.estimatedDeliveryDate ?? Date())
        var daysUntilString = ""
        if (trackingInfo.estimatedDeliveryDate != nil) {
            if daysUntilValue > 0 { daysUntilString = "IN " + String(daysUntilValue) + " DAYS" }
            else if daysUntilValue < 0 { daysUntilString = String(abs(daysUntilValue)) + " DAYS AGO" }
            else { daysUntilString = "TODAY" }
        }
        
        DispatchQueue.main.async {
            cell.trackingNumberButton.setTitle(trackingInfo.trackingNumber, for: .normal)
            let recentStatusUpdate = self.dateToString(mostRecentStatus.date, type: "Event") + "\n" + mostRecentStatus.update + "\n" + mostRecentStatus.location
            cell.closedStatusUpdate.text = recentStatusUpdate
            cell.closedExpectedDeliveryDate.text = trackingInfo.estimatedDeliveryDate != nil ? self.dateToString(trackingInfo.estimatedDeliveryDate!, type: "Estimate") : "N/A"
            cell.closedDaysUntil.text = daysUntilString
            
            if trackingInfo.trackingStatus.statusCategory == "Delivered" {
                cell.sideOfClosedCellView.backgroundColor = UIColor(red: 34/255.0, green: 129/255.0, blue: 39/255.0, alpha: 1)
                cell.closedExpectedOnLabel.text = "DELIVERED ON"
                cell.transitOrDeliveryIcon.image =  #imageLiteral(resourceName: "Delivered Icon")
                cell.closedExpectedDeliveryTime.text = ""
            }
            else {
                cell.closedExpectedOnLabel.text = "EXPECTED ON"
                cell.closedExpectedDeliveryTime.text = "BY 8:00 PM"
            }
            if trackingInfo.estimatedDeliveryDate == nil {
                cell.closedExpectedOnLabel.text = ""
                cell.closedExpectedDeliveryTime.text = ""
            }
        }
    }
    
    public func daysUntil(_ date: Date) -> Int {
        let calendar = Calendar.current
        let startOfDay1 = calendar.startOfDay(for: Date())
        let startOfDay2 = calendar.startOfDay(for: date)
        let components = calendar.dateComponents([.day], from: startOfDay1, to: startOfDay2)
        return components.day!
    }

    public func dateToString(_ date: Date, type: String) -> String {
        let dateFormatter = DateFormatter()
        if type == "Event" { dateFormatter.dateFormat = "M/d/yy 'at' h:mm a" }
        else if type == "Estimate" { dateFormatter.dateFormat = "M/d" }
        return dateFormatter.string(from: date)
    }
    
    override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return trackingNumbersInTable.count
    }

    override func tableView(_: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard case let cell as TrackingInfoCell = cell else {
            return
        }

        cell.backgroundColor = .clear

        if cellHeights[indexPath.row] == closedCellHeight {
            cell.unfold(false, animated: false, completion: nil)
        } else {
            cell.unfold(true, animated: false, completion: nil)
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FoldingCell", for: indexPath) as! FoldingCell
        let durations: [TimeInterval] = [0.26, 0.2, 0.2]
        cell.durationsForExpandedState = durations
        cell.durationsForCollapsedState = durations
        return cell
    }

    override func tableView(_: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeights[indexPath.row]
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        let cell = tableView.cellForRow(at: indexPath) as! FoldingCell

        if cell.isAnimating() {
            return
        }

        var duration = 0.0
        let cellIsCollapsed = cellHeights[indexPath.row] == closedCellHeight
        if cellIsCollapsed {
            cellHeights[indexPath.row] = openedCellHeight
            cell.unfold(true, animated: true, completion: nil)
            duration = 0.5
        } else {
            cellHeights[indexPath.row] = closedCellHeight
            cell.unfold(false, animated: true, completion: nil)
            duration = 0.8
        }

        UIView.animate(withDuration: duration, delay: 0, options: .curveEaseOut, animations: { () -> Void in
            tableView.beginUpdates()
            tableView.endUpdates()
        }, completion: nil)
    }
    
}
