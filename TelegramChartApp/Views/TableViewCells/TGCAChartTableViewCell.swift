//
//  TGCAChartTableViewCell.swift
//  TelegramChartApp
//
//  Created by Igor on 09/03/2019.
//  Copyright © 2019 Fedotov Igor. All rights reserved.
//

import UIKit

class TGCAChartTableViewCell: UITableViewCell {
  
  static let defaultReuseIdd = "TGCAChartTableViewCell"

  var chartView: TGCAChartView!
  var thumbnailChartView: TGCAChartView!
  
  @IBOutlet weak var containerForChartView: UIView!
  @IBOutlet weak var containerForThumbailChartView: UIView!
  
  @IBOutlet weak var headerView: TGCAChartHeaderView!
  @IBOutlet weak var trimmerView: TGCATrimmerView!
  @IBOutlet weak var chartFiltersView: TGCAChartFiltersView!
  
  @IBOutlet weak var chartFiltersHeightConstraint: NSLayoutConstraint!
  
  override func awakeFromNib() {
    super.awakeFromNib()
    headerView?.zoomOutButton.setTitle("Zoom Out", for: .normal)
    
    var fontSize: CGFloat = 14.0
    if UIScreen.main.bounds.width < 375 {
      fontSize = 11.0
    }
    headerView?.label.font = UIFont.systemFont(ofSize: fontSize, weight: .medium)
    selectionStyle = .none
  }
  
  func configure(for chartType: DataChartType) {
    
    containerForThumbailChartView.subviews.forEach{
      $0.removeFromSuperview()
    }
    
    containerForChartView.subviews.forEach{
      $0.removeFromSuperview()
    }
    
    chartView = nil
    thumbnailChartView = nil
    
    var view: TGCAChartView!
    var thumbnailView: TGCAChartView!
    switch chartType {
    case .linear:
      view = TGCALinearChartView(frame: containerForChartView.bounds)
      thumbnailView = TGCALinearChartView(frame: containerForThumbailChartView.bounds)
    case .linearWith2Axes:
      view = TGCALinearChartWithTwoYAxisView(frame: containerForChartView.bounds)
      thumbnailView = TGCALinearChartWithTwoYAxisView(frame: containerForThumbailChartView.bounds)
    case .percentage:
      view = TGCAPercentageChartView(frame: containerForChartView.bounds)
      thumbnailView = TGCAPercentageChartView(frame: containerForThumbailChartView.bounds)
    case .singleBar:
      view = TGCASingleBarChartView(frame: containerForChartView.bounds)
      thumbnailView = TGCASingleBarChartView(frame: containerForThumbailChartView.bounds)
    case .stackedBar:
      view = TGCAStackedBarChartView(frame: containerForChartView.bounds)
      thumbnailView = TGCAStackedBarChartView(frame: containerForThumbailChartView.bounds)
    case .threeDaysComparison:
      view = TGCA3DaysComparisonChartView(frame: containerForChartView.bounds)
      thumbnailView = TGCA3DaysComparisonChartView(frame: containerForThumbailChartView.bounds)
    }
    
    setupChartView(with: view, type: chartType)
    setupThumbnailChartView(with: thumbnailView, type: chartType)
    
  }
  
  //MARK: Transition
  
  func transition(to newType: DataChartType) {
    configure(for: newType)
  }
  
  //MARK: Setup
  
  private func setupChartView(with view: TGCAChartView, type: DataChartType) {
    chartView = view
    chartView.graphLineWidth = 2.0
    chartView.shouldDisplayAxesAndLabels = true
    chartView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    chartView.valuesStartFromZero = type != .linear && type != .linearWith2Axes
    containerForChartView.addSubview(chartView)
  }
  
  private func setupThumbnailChartView(with view: TGCAChartView, type: DataChartType) {
    thumbnailChartView = view
    thumbnailChartView.animatesPositionOnHide = false
    thumbnailChartView.valuesStartFromZero = false
    thumbnailChartView.canShowAnnotations = false
    thumbnailChartView.isUserInteractionEnabled = false
    thumbnailChartView.graphLineWidth = type == .percentage ? 0.0 : 1.0
    thumbnailChartView.layer.cornerRadius = TGCATrimmerView.shoulderWidth * 0.75
    thumbnailChartView.layer.masksToBounds = true
    thumbnailChartView.autoresizingMask  = [.flexibleHeight, .flexibleWidth]
    containerForThumbailChartView.addSubview(thumbnailChartView)

  }
  
}










