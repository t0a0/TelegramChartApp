//
//  TGCAChartTableViewCell.swift
//  TelegramChartApp
//
//  Created by Igor on 09/03/2019.
//  Copyright © 2019 Fedotov Igor. All rights reserved.
//

import UIKit

class TGCAChartTableViewCell: UITableViewCell {

//  @IBOutlet weak var chartView: TGCAChartView!
  weak var chartView: TGCAChartView!
  weak var thumbnailChartView: TGCAChartView!
  
  @IBOutlet weak var headerView: TGCAChartHeaderView!
  @IBOutlet weak var trimmerView: TGCATrimmerView!
  @IBOutlet weak var chartFiltersView: TGCAChartFiltersView!
  
  @IBOutlet weak var chartFiltersHeightConstraint: NSLayoutConstraint!
  override func awakeFromNib() {
    super.awakeFromNib()
    chartView?.graphLineWidth = 2.0
    chartView?.shouldDisplayAxesAndLabels = true
    thumbnailChartView?.animatesPositionOnHide = false
    thumbnailChartView?.valuesStartFromZero = false
    thumbnailChartView?.canShowAnnotations = false
    thumbnailChartView?.isUserInteractionEnabled = false
    thumbnailChartView?.graphLineWidth = 1.0
    thumbnailChartView?.layer.cornerRadius = TGCATrimmerView.shoulderWidth * 0.75
    thumbnailChartView?.layer.masksToBounds = true
    headerView?.zoomOutButton.setTitle("Zoom Out", for: .normal)
    
    var fontSize: CGFloat = 14.0
    if UIScreen.main.bounds.width < 375 {
      fontSize = 11.0
    }
    headerView?.label.font = UIFont.systemFont(ofSize: fontSize, weight: .medium)
    selectionStyle = .none
  }
}










