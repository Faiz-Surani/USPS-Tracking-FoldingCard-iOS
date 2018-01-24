//
//  USPS.swift
//  USPS Tracking
//
//  Created by Faiz Surani on 1/21/18.
//  Copyright © 2018 Faiz Surani. All rights reserved.
//

import Foundation
import Alamofire
import SWXMLHash

class USPS {
    var unparsedXml:String?
    var parsedXml : XMLIndexer?
    let group = DispatchGroup()
    
    public func getTrackingInfo(_ trackingNumber: String) -> TrackingInfo {
        group.enter()
        DispatchQueue.global(qos: DispatchQoS.background.qosClass).async {
            self.callRestService(requestUrl: self.getRequest(trackingNumber))
        }
        group.wait()
        parsedXml = SWXMLHash.parse(unparsedXml!)["TrackResponse"]["TrackInfo"]
        return populateTrackingInfo(trackingNumber: trackingNumber)
    }
    
    fileprivate func populateTrackingInfo(trackingNumber: String) -> TrackingInfo {
        let trackingData = TrackingInfo()
        trackingData.trackingNumber = trackingNumber
        if parsedXml!["PredictedDeliveryDate"].element?.text != "" {
            trackingData.estimatedDeliveryDate = parseDate((parsedXml!["PredictedDeliveryDate"].element?.text)!, dateType: "Estimate")
        }
        trackingData.trackingStatus = constructStatus()
        trackingData.destinationZipCode = parsedXml!["DestinationZip"].element?.text ?? ""
        return trackingData
    }
    
    fileprivate func populateTrackingUpdateArray() -> [TrackingUpdate] {
        var trackingUpdateArray = [TrackingUpdate]()
        trackingUpdateArray.append(constructTrackingUpdate(parsedXml!["TrackSummary"]))
        return trackingUpdateArray
    }
    
    fileprivate func constructTrackingUpdate(_ xmlOfUpdate: XMLIndexer) -> TrackingUpdate {
        let trackingUpdate = TrackingUpdate()
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
        return trackingUpdate
    }
    
    fileprivate func constructStatus() -> TrackingStatus {
        let trackingStatus = TrackingStatus()
        trackingStatus.status = (parsedXml!["Status"].element?.text)  ?? ""
        trackingStatus.statusCategory = (parsedXml!["StatusCategory"].element?.text) ?? ""
        trackingStatus.statusSummary = (parsedXml!["StatusSummary"].element?.text) ?? ""
        return trackingStatus
    }
    
    fileprivate func parseDate(_ date: String, dateType: String) -> Date {
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
    
    public func callRestService(requestUrl:String) ->Void
    {
        var request = URLRequest(url: URL(string: requestUrl)!)
        request.httpMethod = "GET"
        
        let session = URLSession.shared
        let task = session.dataTask(with: request, completionHandler: serviceCallback)
        
        task.resume()
    }
    
    private func serviceCallback(data:Data? , response:URLResponse? , error:Error? ) -> Void
    {
        unparsedXml = String(data: data!, encoding: .utf8)
        self.group.leave()
    }
 
}

class TrackingInfo {
    var trackingNumber = ""
    var estimatedDeliveryDate : Date?
    var trackingUpdates = [TrackingUpdate]()
    var trackingStatus = TrackingStatus()
    var destinationZipCode = ""
}

class TrackingUpdate {
    var date = Date()
    var update = ""
    var location = ""
}

class TrackingStatus {
    var status = ""
    var statusSummary = ""
    var statusCategory = ""
}

