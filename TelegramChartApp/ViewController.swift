//
//  ViewController.swift
//  TelegramChartApp
//
//  Created by Igor on 09/03/2019.
//  Copyright © 2019 Fedotov Igor. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
  @IBOutlet weak var trimmerView: TGCATrimmerView!
  @IBOutlet weak var tableView: UITableView!
  
//  let dataSetService = TGCADataSetService(dataSets: [(dataSet, "1"),
//                                                     (dataSet, "2"),
//                                                     (dataSet, "3"),
//                                                     (dataSet, "4")])
  
  override func viewDidLoad() {
    super.viewDidLoad()
    tableView.register(UINib(nibName: "TGCAButtonTableViewCell", bundle: nil), forCellReuseIdentifier: TGCAButtonTableViewCell.defaultReuseId)
    tableView.register(UINib(nibName: "TGCAChartTableViewCell", bundle: nil), forCellReuseIdentifier: TGCAChartTableViewCell.defaultReuseId)
    title = "Statistics"
    trimmerView.delegate = self
  }

  var cccccell: TGCAChartTableViewCell?
  var dataSet: DataSet {
    var pts = [DataSetPoint]()
    for _ in 0...50 {
      pts.append(DataSetPoint(x:CGFloat.random(in: 0.0..<10000.0), y: CGFloat.random(in: 0.0..<10000.0)))
    }
    return DataSet(points: pts.sorted(by: { (left, right) -> Bool in
      left.x < right.x
    }))
  }
}

extension ViewController: UITableViewDataSource {
  
  func numberOfSections(in tableView: UITableView) -> Int {
    return 2
  }
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return section == 0 ? 3 : 1
  }
  
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if indexPath.section == 0 {
      if indexPath.row == 0 {
        let cell = tableView.dequeueReusableCell(withIdentifier: TGCAChartTableViewCell.defaultReuseId) as! TGCAChartTableViewCell
        cell.chartView.addDataSet(dataSet, color: .red)
        cell.chartView.addDataSet(dataSet, color: .green)
        cccccell = cell
        return cell
      } else {
        return UITableViewCell()
      }
    } else {
      let cell = tableView.dequeueReusableCell(withIdentifier: TGCAButtonTableViewCell.defaultReuseId) as! TGCAButtonTableViewCell
      cell.onClickHandler = {
        let random = CGFloat.random(in: -1000..<3500.0)...CGFloat.random(in: 3700..<11001)
        self.cccccell?.chartView.changeDisplayedRange(random)
        cell.button.setTitle("\(random)", for: .normal)
      }
      return cell
    }
  }
  func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    return section == 0 ? "Followers" : nil
  }
  
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return indexPath.section == 0 && indexPath.row == 0 ? 300 : 44.0
  }
}

extension ViewController: UITableViewDelegate {
  
}




extension ViewController: TGCATrimmerViewDelegate {
  func chartSlider(_ chartSlider: TGCATrimmerView, didChangeDisplayRange range: ClosedRange<CGFloat>) {
    cccccell?.chartView.changeDisplayedRange(range)
  }
  
  
}
