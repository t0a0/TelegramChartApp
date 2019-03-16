//
//  TGCAColorTheme.swift
//  TelegramChartApp
//
//  Created by Igor on 16/03/2019.
//  Copyright © 2019 Fedotov Igor. All rights reserved.
//

import Foundation
import UIKit

struct TGCAColorTheme {
  
  let themId_normal = "Normal"
  let themeId_dark = "Darl"
  
  static let normal = TGCAColorTheme(
    identifier: ThemeIdentifier.normal,
    backgroundColor: UIColor(red: 239.0/255.0, green: 239.0/255.0, blue: 244.0/255.0, alpha: 1),
    foregroundColor: UIColor(red: 254.0/255.0, green: 254.0/255.0, blue: 254.0/255.0, alpha: 1),
    accentColor: UIColor(red: 0.0/255.0, green: 126.0/255.0, blue: 229.0/255.0, alpha: 1),
    buttonTextColor: UIColor(red: 24.0/255.0, green: 145.0/255.0, blue: 255.0/255.0, alpha: 1),
    mainTextColor: UIColor.black,
    axisColor: UIColor(red: 207.0/255.0, green: 209.0/255.0, blue: 210.0/255.0, alpha: 1),
    axisLabelColor: UIColor(red: 152.0/255.0, green: 158.0/255.0, blue: 163.0/255.0, alpha: 1),
    trimmerShoulderColor: UIColor(red: 202.0/255.0, green: 212.0/255.0, blue: 222.0/255.0, alpha: 1),
    statusBarStyle: .default)
  
  static let dark = TGCAColorTheme(
    identifier: ThemeIdentifier.dark,
    backgroundColor: UIColor(red: 24.0/255.0, green: 34.0/255.0, blue: 45.0/255.0, alpha: 1),
    foregroundColor: UIColor(red: 33.0/255.0, green: 47.0/255.0, blue: 63.0/255.0, alpha: 1),
    accentColor: UIColor(red: 0.0/255.0, green: 126.0/255.0, blue: 229.0/255.0, alpha: 1),
    buttonTextColor: UIColor(red: 24.0/255.0, green: 145.0/255.0, blue: 255.0/255.0, alpha: 1),
    mainTextColor: UIColor.white,
    axisColor: UIColor(red: 19.0/255.0, green: 27.0/255.0, blue: 35.0/255.0, alpha: 1),
    axisLabelColor: UIColor(red: 93.0/255.0, green: 109.0/255.0, blue: 126.0/255.0, alpha: 1),
    trimmerShoulderColor: UIColor(red: 53.0/255.0, green: 70.0/255.0, blue: 89.0/255.0, alpha: 1),
    statusBarStyle: .lightContent)
  
  let identifier: ThemeIdentifier
  let backgroundColor: UIColor
  let foregroundColor: UIColor
  let accentColor: UIColor
  let buttonTextColor: UIColor
  let mainTextColor: UIColor
  let axisColor: UIColor
  let axisLabelColor: UIColor
  let trimmerShoulderColor: UIColor
  let statusBarStyle: UIStatusBarStyle
}

enum ThemeIdentifier: String {
  case dark = "Dark"
  case normal = "Normal"
}
