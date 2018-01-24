//
//  DemoCell.swift
//
//  Created by Faiz Surani on 1/20/18.
//  Copyright © 2018 Faiz Surani. All rights reserved.
//

import FoldingCell
import UIKit
import MapKit

class DemoCell: FoldingCell {

    @IBOutlet weak var closedCellTitle: UILabel!
    @IBOutlet weak var transitOrDeliveryIcon: UIImageView!
    @IBOutlet weak var trackingNumberButton: UIButton!
    @IBOutlet weak var sideOfClosedCellView: UIView!
    @IBOutlet weak var closedStatusUpdate: UILabel!
    @IBOutlet weak var closedDaysUntil: UILabel!
    @IBOutlet weak var closedExpectedDeliveryDate: UILabel!
    @IBOutlet weak var closedExpectedDeliveryTime: UILabel!
    
    @IBOutlet weak var openCellTitle: UILabel!
    @IBOutlet weak var openMapView: MKMapView!

    override func awakeFromNib() {
        super.awakeFromNib()
        setupCell()
    }

    fileprivate func setupCell() {
        foregroundView.layer.cornerRadius = 10
        foregroundView.layer.masksToBounds = true
        transitOrDeliveryIcon.image = transitOrDeliveryIcon.image?.withRenderingMode(.alwaysTemplate)
        trackingNumberButton.contentHorizontalAlignment = .left
        
    }
    
    public func refreshData() {
        
    }
    
    override func animationDuration(_ itemIndex: NSInteger, type _: FoldingCell.AnimationType) -> TimeInterval {
        let durations = [0.26, 0.2, 0.2]
        return durations[itemIndex]
    }
}

