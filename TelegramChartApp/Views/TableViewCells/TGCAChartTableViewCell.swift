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
  
  func configure(with chartContainer: ChartContainer) {
    
    containerForThumbailChartView.subviews.forEach{
      $0.removeFromSuperview()
    }
    
    containerForChartView.subviews.forEach{
      $0.removeFromSuperview()
    }
    
    var view: TGCAChartView!
    var thumbnailView: TGCAChartView!
    switch chartContainer.chart.type {
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
    }
    
    setupChartView(with: view)
    setupThumbnailChartView(with: thumbnailView)
    
    containerForChartView.addSubview(view)
    containerForThumbailChartView.addSubview(thumbnailView)
    

//    view.configure(with: chartContainer.chart, hiddenIndicies: chartContainer.hiddenIndicies, displayRange: chartContainer.trimRange)
//    thumbnailView.configure(with: chartContainer.chart, hiddenIndicies: chartContainer.hiddenIndicies, displayRange: CGFloatRangeInBounds.ZeroToOne)
    
  }
  
  private func setupChartView(with view: TGCAChartView) {
    chartView = view
    chartView.graphLineWidth = 2.0
    chartView.shouldDisplayAxesAndLabels = true
    chartView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
  }
  
  private func setupThumbnailChartView(with view: TGCAChartView) {
    thumbnailChartView = view
    thumbnailChartView.animatesPositionOnHide = false
    thumbnailChartView.valuesStartFromZero = false
    thumbnailChartView.canShowAnnotations = false
    thumbnailChartView.isUserInteractionEnabled = false
    thumbnailChartView.graphLineWidth = 1.0
    thumbnailChartView.layer.cornerRadius = TGCATrimmerView.shoulderWidth * 0.75
    thumbnailChartView.layer.masksToBounds = true
    thumbnailChartView.autoresizingMask  = [.flexibleHeight, .flexibleWidth]
  }
  
}










