//
//  TGCAChartDetailViewController.swift
//  TelegramChartApp
//
//  Created by Igor on 10/03/2019.
//  Copyright © 2019 Fedotov Igor. All rights reserved.
//

import Foundation
import UIKit

class TGCAChartDetailViewController: UIViewController {
  
  @IBOutlet weak var trimmerView: TGCATrimmerView!
  @IBOutlet weak var tableView: UITableView!
  
  var chart: LinearChart?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    tableView.register(UINib(nibName: "TGCAButtonTableViewCell", bundle: nil), forCellReuseIdentifier: TGCAButtonTableViewCell.defaultReuseId)
    tableView.register(UINib(nibName: "TGCAChartTableViewCell", bundle: nil), forCellReuseIdentifier: TGCAChartTableViewCell.defaultReuseId)
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "chartColumnLabelCell")
    title = "Statistics"
    navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    tableView.showsVerticalScrollIndicator = false
    tableView.showsHorizontalScrollIndicator = false
    trimmerView.delegate = self
  }
  
  var chartCell: TGCAChartTableViewCell? {
    return tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? TGCAChartTableViewCell
  }
  
}

extension TGCAChartDetailViewController: UITableViewDataSource {
  
  func numberOfSections(in tableView: UITableView) -> Int {
    return 2
  }
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    switch section {
    case 0:
      guard let chart = chart else {
        return 0
      }
      return chart.yVectors.count + 1
    default:
      return 1
    }
  }
  
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if indexPath.section == 0 {
      if indexPath.row == 0 {
        let cell = tableView.dequeueReusableCell(withIdentifier: TGCAChartTableViewCell.defaultReuseId) as! TGCAChartTableViewCell
        if let chart = chart {
          cell.chartView.configure(with: chart)
        }
        cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: CGFloat.greatestFiniteMagnitude)
        cell.directionalLayoutMargins = .zero
        cell.selectionStyle = .none
        return cell
      } else {
        let cell = tableView.dequeueReusableCell(withIdentifier: "chartColumnLabelCell")!
        //TODO: FIX LABEL POSITION
        if let chart = chart {
          cell.imageView?.image = UIImage.from(color: chart.yVectors[indexPath.row - 1].metaData.color, size: CGSize(width: 12, height: 12))
        }
        cell.imageView?.layer.cornerRadius = 3.0
        cell.imageView?.clipsToBounds = true
        //TODO: THIS IS NOT CORRECT, SHOULD USE REL IDENTIFIER NOT LABEL
        cell.textLabel?.text = chart?.yVectors[indexPath.row - 1].metaData.identifier
        cell.accessoryType = .checkmark
        return cell
      }
    } else {
      let cell = tableView.dequeueReusableCell(withIdentifier: TGCAButtonTableViewCell.defaultReuseId) as! TGCAButtonTableViewCell
      cell.selectionStyle = .none
      return cell
    }
  }
  
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return indexPath.section == 0 && indexPath.row == 0 ? 300 : 44.0
  }
}

extension TGCAChartDetailViewController: UITableViewDelegate {
  
  func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    return section == 0 ? chart?.title : nil
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    if indexPath.section == 0 {
      chartCell?.chartView.hide(at: indexPath.row - 1)
    }
  }
}

extension TGCAChartDetailViewController: TGCATrimmerViewDelegate {
  
  func chartSlider(_ chartSlider: TGCATrimmerView, didChangeDisplayRange range: ClosedRange<CGFloat>) {
    chartCell?.chartView.displayRange = range
  }
  
  
}