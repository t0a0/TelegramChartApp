//
//  TGCAFilterButton.swift
//  TelegramChartApp
//
//  Created by Igor on 07/04/2019.
//  Copyright © 2019 Fedotov Igor. All rights reserved.
//

import Foundation
import UIKit

class TGCAFilterButton: UIButton {
  static let borderWidth: CGFloat = 1.0
  static let cornerRadius: CGFloat = 5.0
  static let buttonHeight: CGFloat = 30.0
  static let marginsWidth: CGFloat = 20.0
  static let checkmarkPrefix = "✓ "
  
  private var checked: Bool = true
  private var titleText: String?
  private var color: UIColor?
  
  override init(frame: CGRect) {
    super.init(frame: frame)
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  func setup() {
    clipsToBounds = true
    layer.masksToBounds = true
    layer.cornerRadius = TGCAFilterButton.cornerRadius
    layer.borderColor = color?.cgColor
  }
  
  func configure(checked: Bool, titleText: String, color: UIColor) -> CGFloat {
    self.checked = checked
    self.titleText = titleText
    self.color = color
    update()
    return sizeThatFits(CGSize(width: .greatestFiniteMagnitude, height: TGCAFilterButton.buttonHeight)).width + TGCAFilterButton.marginsWidth
  }
  
  func toggleChecked() {
    checked.toggle()
    update()
  }
  
  override var isHighlighted: Bool {
    didSet {
      if checked {
        backgroundColor = backgroundColor?.withAlphaComponent(self.isHighlighted ? 0.25 : 1)
      } else {
        layer.borderColor = color?.withAlphaComponent(self.isHighlighted ? 0.25 : 1).cgColor
      }
    }
  }
  
  private func update() {
    
    func animBlock() {
      setTitle((checked ? TGCAFilterButton.checkmarkPrefix : "") + (titleText ?? ""), for: .normal)
      setTitleColor(checked ? .white : color, for: .normal)
      backgroundColor = checked ? color : .clear
      
    }
    
    layer.borderWidth = checked ? 0 : TGCAFilterButton.borderWidth

    UIView.performWithoutAnimation {
      animBlock()
      layoutIfNeeded()
    }
  }
  
}
