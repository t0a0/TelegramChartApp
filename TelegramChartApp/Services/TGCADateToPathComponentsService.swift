//
//  TGCADateToPathComponentsService.swift
//  TelegramChartApp
//
//  Created by Igor on 11/04/2019.
//  Copyright © 2019 Fedotov Igor. All rights reserved.
//

import Foundation
import UIKit

class TGCADateToPathComponentsService {
  
  struct PathComponents {
    let folder: String
    let fileName: String
  }
  
  private lazy var yearMonthFormatter: DateFormatter = {
    let df = DateFormatter()
    df.locale = Locale(identifier: "en_US")
    df.dateFormat = "YYYY-MM"
    return df
  }()
  
  private lazy var dayFormatter: DateFormatter = {
    let df = DateFormatter()
    df.locale = Locale(identifier: "en_US")
    df.dateFormat = "dd"
    return df
  }()
  
  func pathComponents(for date: Date) -> PathComponents {
    return PathComponents(folder: yearMonthFormatter.string(from: date),
                          fileName: dayFormatter.string(from: date))
  }
  
}
