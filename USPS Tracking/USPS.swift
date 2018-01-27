//
//  USPS.swift
//  USPS Tracking
//
//  Created by Faiz Surani on 1/21/18.
//  Copyright © 2018 Faiz Surani. All rights reserved.
//

import Foundation
import SWXMLHash

class USPS {
    var parsedXml: XMLIndexer?
    
    public func getTrackingInfo(_ trackingNumber: String, completion: @escaping (TrackingInfo?, Error?) -> Void) {
        self.callRestService(requestUrl: self.getRequest(trackingNumber)) { data, response, error in
            guard error == nil, let returnData = data else {
                completion(nil, error)
                return
            }
            self.parsedXml = SWXMLHash.parse(returnData)["TrackResponse"]["TrackInfo"]
            let finishedTrackingInfo = self.populateTrackingInfo(trackingNumber)
            completion(finishedTrackingInfo, nil)
        }
    }
    
    fileprivate func callRestService(requestUrl:String, completion: @escaping (Data?, URLResponse?, Error?) -> Void) -> Void
    {
        var request = URLRequest(url: URL(string: requestUrl)!)
        request.httpMethod = "GET"
        let session = URLSession.shared
        let task = session.dataTask(with: request, completionHandler: completion)
        task.resume()
    }
    
    fileprivate func populateTrackingInfo(_ trackingNumber: String) -> TrackingInfo {
        var trackingData = TrackingInfo()
        trackingData.trackingNumber = trackingNumber
        if parsedXml!["PredictedDeliveryDate"].element?.text != nil {
            trackingData.estimatedDeliveryDate = parseDate((parsedXml!["PredictedDeliveryDate"].element?.text)!, dateType: "Estimate")
        }
        else if parsedXml!["ExpectedDeliveryDate"].element?.text != nil {
            trackingData.estimatedDeliveryDate = parseDate((parsedXml!["ExpectedDeliveryDate"].element?.text)!, dateType: "Estimate")
        }
        trackingData.trackingStatus = constructStatus()
        trackingData.trackingUpdates = populateTrackingUpdateArray()
        trackingData.destinationZipCode = parsedXml!["DestinationZip"].element?.text ?? ""
        return trackingData
    }
    
    fileprivate func populateTrackingUpdateArray() -> [TrackingUpdate] {
        var trackingUpdateArray = [TrackingUpdate]()
        trackingUpdateArray.append(constructTrackingUpdate(parsedXml!["TrackSummary"]))
        for trackUpdate in parsedXml!["TrackDetail"].all {
            trackingUpdateArray.append(constructTrackingUpdate(trackUpdate))
        }
        return trackingUpdateArray
    }
    
    fileprivate func constructTrackingUpdate(_ xmlOfUpdate: XMLIndexer) -> TrackingUpdate {
        var trackingUpdate = TrackingUpdate()
        trackingUpdate.update = xmlOfUpdate["Event"].element?.text ?? "Error: Not Found"
        let city = xmlOfUpdate["EventCity"].element?.text ?? "Error: Not Found"
        let state = xmlOfUpdate["EventState"].element?.text
        if state != "" {
            let zipCode = xmlOfUpdate["EventZIPCode"].element?.text
            trackingUpdate.location = city + ", " + state! + " " + zipCode!
        }
        else {
            trackingUpdate.location = city
        }
        let dateString = (xmlOfUpdate["EventTime"].element?.text)! + " " + (xmlOfUpdate["EventDate"].element?.text)!
        trackingUpdate.date = parseDate(dateString, dateType: "Event")
        return trackingUpdate
    }
    
    fileprivate func constructStatus() -> TrackingStatus {
        var trackingStatus = TrackingStatus()
        trackingStatus.status = (parsedXml!["Status"].element?.text)  ?? ""
        trackingStatus.statusCategory = (parsedXml!["StatusCategory"].element?.text) ?? ""
        trackingStatus.statusSummary = (parsedXml!["StatusSummary"].element?.text) ?? ""
        return trackingStatus
    }
    
    public func parseDate(_ date: String, dateType: String) -> Date {
        let dateFormatter = DateFormatter()
        if dateType == "Estimate" {
            dateFormatter.dateFormat = "MMMM d, yyyy"
        }
        else if dateType == "Event" {
            dateFormatter.dateFormat = "h:mm a MMMM d, yyyy"
        }
        let parsedDate = dateFormatter.date(from: date) ?? Date()
        return parsedDate
    }
    
    fileprivate func getRequest(_ trackingNumber: String) -> String {
        let APIUsername = "731PERSO0590"
        let trackingXmlLink = "http://production.shippingapis.com/ShippingAPI.dll?API=TrackV2&XML=%3CTrackFieldRequest%20USERID=%22" + APIUsername + "%22%3E%20%3CRevision%3E1%3C/Revision%3E%20%3CClientIp%3E127.0.0.1%3C/ClientIp%3E%20%3CSourceId%3EFaiz%20Surani%3C/SourceId%3E%20%3CTrackID%20ID=%22" + trackingNumber + "%22%3E%20%3CDestinationZipCode%3E66666%3C/DestinationZipCode%3E%20%3CMailingDate%3E2010-01-01%3C/MailingDate%3E%20%3C/TrackID%3E%20%3C/TrackFieldRequest%3E"
        return trackingXmlLink
    }
 
}

struct TrackingInfo {
    var name = ""
    var trackingNumber = ""
    var estimatedDeliveryDate : Date?
    var trackingUpdates = [TrackingUpdate]()
    var trackingStatus = TrackingStatus()
    var destinationZipCode = ""
}

struct TrackingUpdate {
    var date = Date()
    var update = ""
    var location = ""
}

struct TrackingStatus {
    var status = ""
    var statusSummary = ""
    var statusCategory = ""
}

struct UserEnteredInfo {
    var name = ""
    var sender = ""
    var info = ""
}

class StoredTrackingData: NSObject, NSCoding {
    func encode(with aCoder: NSCoder) {
        aCoder.encode(trackingNumber, forKey: "trackingNumber")
        aCoder.encode(name, forKey: "name")
        aCoder.encode(sender, forKey: "sender")
        aCoder.encode(recentUpdate, forKey: "recentUpdate")
        aCoder.encode(statusCategory, forKey: "statusCategory")
    }
    
    required convenience init(coder aDecoder: NSCoder) {
        let trackingNumber = aDecoder.decodeObject(forKey: "trackingNumber") as! String
        let name = aDecoder.decodeObject(forKey: "name") as! String
        let sender =  aDecoder.decodeObject(forKey: "sender") as! String
        let recentUpdate = aDecoder.decodeObject(forKey: "recentUpdate") as! String
        let statusCategory = aDecoder.decodeObject(forKey: "statusCategory") as! String
        self.init(trackingNumber: trackingNumber, name: name, sender: sender, recentUpdate: recentUpdate, statusCategory: statusCategory)
    }
    
    init(trackingNumber: String, name: String, sender: String, recentUpdate: String, statusCategory: String) {
        
    }
    
    var trackingNumber = ""
    var name = ""
    var sender = ""
    var recentUpdate = ""
    var statusCategory = ""
}

