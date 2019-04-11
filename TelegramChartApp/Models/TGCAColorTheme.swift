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
  
  let identifier: ThemeIdentifier
  let backgroundColor: UIColor
  let foregroundColor: UIColor
  let accentColor: UIColor
  let mainTextColor: UIColor
  let axisColor: UIColor
  let axisLabelColor: UIColor
  let trimmerShoulderColor: UIColor
  let annotationColor: UIColor
  let annotationLabelColor: UIColor
  let annotationDisclosureIndicatorColor: UIColor
  let tableViewFooterHeaderColor: UIColor
  let statusBarStyle: UIStatusBarStyle
  
  static let normal = TGCAColorTheme(
    identifier: ThemeIdentifier.normal,
    backgroundColor: UIColor(red: 235.0/255.0, green: 235.0/255.0, blue: 241.0/255.0, alpha: 1),
    foregroundColor: .white,
    accentColor: UIColor(red: 10.0/255.0, green: 96.0/255.0, blue: 254.0/255.0, alpha: 1),
    mainTextColor: UIColor.black,
    axisColor: UIColor(red: 24.0/255.0, green: 45.0/255.0, blue: 59.0/255.0, alpha: 0.2),
    axisLabelColor: UIColor(red: 123.0/255.0, green: 123.0/255.0, blue: 129.0/255.0, alpha: 1),
    trimmerShoulderColor: UIColor(red: 179.0/255.0, green: 198.0/255.0, blue: 217.0/255.0, alpha: 1),
    annotationColor: UIColor(red: 241.0/255.0, green: 241.0/255.0, blue: 245.0/255.0, alpha: 1),
    annotationLabelColor: UIColor(red: 90.0/255.0, green: 90.0/255.0, blue: 95.0/255.0, alpha: 1),
    annotationDisclosureIndicatorColor: UIColor(red: 184.0/255.0, green: 186.0/255.0, blue: 194.0/255.0, alpha: 1),
    tableViewFooterHeaderColor: UIColor(red: 90.0/255.0, green: 90.0/255.0, blue: 95.0/255.0, alpha: 1),
    statusBarStyle: .default)
  
  static let dark = TGCAColorTheme(
    identifier: ThemeIdentifier.dark,
    backgroundColor: UIColor(red: 19.0/255.0, green: 24.0/255.0, blue: 34.0/255.0, alpha: 1),
    foregroundColor: UIColor(red: 25.0/255.0, green: 35.0/255.0, blue: 48.0/255.0, alpha: 1),
    accentColor: UIColor(red: 39.0/255.0, green: 146.0/255.0, blue: 254.0/255.0, alpha: 1),
    mainTextColor: UIColor.white,
    axisColor: UIColor(red: 133.0/255.0, green: 150.0/255.0, blue: 171.0/255.0, alpha: 0.2),
    axisLabelColor: UIColor(red: 115.0/255.0, green: 131.0/255.0, blue: 155.0/255.0, alpha: 1),
    trimmerShoulderColor: UIColor(red: 68.0/255.0, green: 79.0/255.0, blue: 89.0/255.0, alpha: 1),
    annotationColor: UIColor(red: 19.0/255.0, green: 26.0/255.0, blue: 36.0/255.0, alpha: 1),
    annotationLabelColor: .white,
    annotationDisclosureIndicatorColor: UIColor(red: 59.0/255.0, green: 66.0/255.0, blue: 67.0/255.0, alpha: 1),
    tableViewFooterHeaderColor: UIColor(red: 115.0/255.0, green: 132.0/255.0, blue: 156.0/255.0, alpha: 1),
    statusBarStyle: .lightContent)
  
}

enum ThemeIdentifier: String {
  case dark = "Dark"
  case normal = "Normal"
}
