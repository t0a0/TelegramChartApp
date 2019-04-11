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
  let chartMaskColor: UIColor
  let trimmerMaskColor: UIColor
  let statusBarStyle: UIStatusBarStyle
  
  static let normal = TGCAColorTheme(
    identifier: ThemeIdentifier.normal,
    backgroundColor: UIColor(red: 235.0/255.0, green: 235.0/255.0, blue: 241.0/255.0, alpha: 1),
    foregroundColor: .white,
    accentColor: UIColor(hex: "108BE3")!,
    mainTextColor: UIColor.black,
    axisColor: UIColor(hex: "182D3B", a: 0.1)!,
    axisLabelColor: UIColor(red: 123.0/255.0, green: 123.0/255.0, blue: 129.0/255.0, alpha: 1),
    trimmerShoulderColor: UIColor(hex: "C0D1E1")!,
    annotationColor: UIColor(red: 241.0/255.0, green: 241.0/255.0, blue: 245.0/255.0, alpha: 1),
    annotationLabelColor: UIColor(red: 90.0/255.0, green: 90.0/255.0, blue: 95.0/255.0, alpha: 1),
    annotationDisclosureIndicatorColor: UIColor(hex: "59606D", a: 0.3)!,
    tableViewFooterHeaderColor: UIColor(red: 90.0/255.0, green: 90.0/255.0, blue: 95.0/255.0, alpha: 1),
    chartMaskColor: .init(white: 1.0, alpha: 0.5),
    trimmerMaskColor: UIColor(hex: "E2EEF9", a: 0.6)!,
    statusBarStyle: .default)
  
  static let dark = TGCAColorTheme(
    identifier: ThemeIdentifier.dark,
    backgroundColor: UIColor(red: 19.0/255.0, green: 24.0/255.0, blue: 34.0/255.0, alpha: 1),
    foregroundColor: UIColor(red: 25.0/255.0, green: 35.0/255.0, blue: 48.0/255.0, alpha: 1),
    accentColor: UIColor(hex: "2EA6FE")!,
    mainTextColor: UIColor.white,
    axisColor: UIColor(hex: "8596AB", a: 0.2)!,
    axisLabelColor: UIColor(red: 115.0/255.0, green: 131.0/255.0, blue: 155.0/255.0, alpha: 1),
    trimmerShoulderColor: UIColor(hex: "56626D")!,
    annotationColor: UIColor(red: 19.0/255.0, green: 26.0/255.0, blue: 36.0/255.0, alpha: 1),
    annotationLabelColor: .white,
    annotationDisclosureIndicatorColor: UIColor(hex: "D2D5D7")!,
    tableViewFooterHeaderColor: UIColor(red: 115.0/255.0, green: 132.0/255.0, blue: 156.0/255.0, alpha: 1),
    chartMaskColor: UIColor(hex: "212F3F", a: 0.5)!,
    trimmerMaskColor: UIColor(hex: "18222D", a: 0.6)!,
    statusBarStyle: .lightContent)
  
}

enum ThemeIdentifier: String {
  case dark = "Dark"
  case normal = "Normal"
}
