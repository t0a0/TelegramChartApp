//
//  TGCAChartTableViewCell.swift
//  TelegramChartApp
//
//  Created by Igor on 09/03/2019.
//  Copyright © 2019 Fedotov Igor. All rights reserved.
//

import UIKit

class TGCAChartTableViewCell: UITableViewCell, CAAnimationDelegate {
  
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
  
  func configure(for chartType: DataChartType, remove: Bool = true) {
    
    if remove {
      containerForThumbailChartView.subviews.forEach{
        $0.removeFromSuperview()
      }
      
      containerForChartView.subviews.forEach{
        $0.removeFromSuperview()
      }
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
    case .pie:
      view = TGCAPieChartView(frame: containerForChartView.bounds)
      thumbnailView = TGCASquarePercentageChartView(frame: containerForThumbailChartView.bounds)
    }
    
    setupChartView(with: view, type: chartType)
    setupThumbnailChartView(with: thumbnailView, type: chartType)
    
  }
  
  //MARK: Transition
  
  func transition(to newType: DataChartType) {
    let oldChartView = containerForChartView.subviews.first!
    let oldThumbnaiView = containerForThumbailChartView.subviews.first!
    
    
    configure(for: newType, remove: false)
    
    chartView.isHidden = true
    thumbnailChartView.isHidden = true
    
    let transition = fadeTransition()
    

    
    containerForChartView.layer.add(transition, forKey: "chartContainer")
    containerForThumbailChartView.layer.add(transition, forKey: "thumbnailChartContainer")
    headerView.layer.add(transition, forKey: "header")

    if newType == .singleBar || newType == .threeDaysComparison {
      chartFiltersView.layer.add(transition, forKey: "filtersView")
      trimmerView.layer.add(transition, forKey: "trimmerView")
    }
    
    oldChartView.isHidden = true
    oldThumbnaiView.isHidden = true
    chartView.isHidden = false
    thumbnailChartView.isHidden = false
  }
  
  func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
    containerForChartView.subviews.forEach{
      if $0 != chartView {
        $0.removeFromSuperview()
      }
    }
    containerForThumbailChartView.subviews.forEach{
      if $0 != thumbnailChartView {
        $0.removeFromSuperview()
      }
    }
  }
  
  func fadeTransition() -> CATransition{
    let transition = CATransition()
    transition.duration = CHART_ZOOM_ANIMATION_DURATION
    transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
    transition.type = .fade
    transition.delegate = self
    return transition
  }
  
  //MARK: Setup
  
  private func setupChartView(with view: TGCAChartView, type: DataChartType) {
    chartView = view
    chartView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    
    chartView.setChartConfiguration(chartConfig(for: type, isThumbnail: false))
    
    containerForChartView.addSubview(chartView)
  }
  
  private func setupThumbnailChartView(with view: TGCAChartView, type: DataChartType) {
    thumbnailChartView = view
    thumbnailChartView.isUserInteractionEnabled = false
    thumbnailChartView.layer.cornerRadius = TGCATrimmerView.shoulderWidth * 0.75
    thumbnailChartView.layer.masksToBounds = true
    thumbnailChartView.autoresizingMask  = [.flexibleHeight, .flexibleWidth]
    
    thumbnailChartView.setChartConfiguration(chartConfig(for: type, isThumbnail: true))
    
    containerForThumbailChartView.addSubview(thumbnailChartView)

  }
  
  private func chartConfig(for type: DataChartType, isThumbnail: Bool) -> TGCAChartView.ChartConfiguration {
    switch type {
    case .linear, .linearWith2Axes, .threeDaysComparison:
      return isThumbnail ? TGCAChartView.ChartConfiguration.ThumbnailDefault : TGCAChartView.ChartConfiguration.Default
    case .percentage:
      return isThumbnail ? TGCAChartView.ChartConfiguration.PercentageThumbnailChartConfiguration : TGCAChartView.ChartConfiguration.PercentageChartConfiguration
    case .singleBar, .stackedBar, .pie:
      return isThumbnail ? TGCAChartView.ChartConfiguration.BarThumbnailChartConfiguration : TGCAChartView.ChartConfiguration.BarChartConfiguration
    }
  }
  
}










