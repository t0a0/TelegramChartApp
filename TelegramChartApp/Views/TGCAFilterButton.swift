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
  
  var onLongTap: (()->())?
  var onTap: (()->())?
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    commonInit()
  }
  
  func commonInit() {
    setup()
    addLongPressGesture()
    addTarget(self, action: #selector(TGCAFilterButton.handleTap(_:)), for: .touchUpInside)
  }
  
  private func setup() {
    layer.masksToBounds = true
    layer.cornerRadius = TGCAFilterButton.cornerRadius
  }
  
  private func addLongPressGesture() {
    let longTapGR = UILongPressGestureRecognizer(target: self, action: #selector(TGCAFilterButton.handleLongTap(_:)))
    longTapGR.minimumPressDuration = 0.75
    addGestureRecognizer(longTapGR)
  }
  
  @objc private func handleLongTap(_ gr: UILongPressGestureRecognizer) {
    if gr.state == .began {
      cancelTracking(with: nil)
      onLongTap?()
    }
  }
  
  @objc private func handleTap(_ sender: Any) {
    cancelTracking(with: nil)
    onTap?()
  }
  
  func configure(checked: Bool, titleText: String, color: UIColor) -> CGFloat {
    self.checked = checked
    self.titleText = titleText
    self.color = color
    update()
    return sizeThatFits(CGSize(width: .greatestFiniteMagnitude, height: TGCAFilterButton.buttonHeight)).width + TGCAFilterButton.marginsWidth
  }
  
  var isChecked: Bool {
    return checked
  }
  
  func toggleChecked() {
    checked.toggle()
    update()
  }
  
  func check() {
    if !checked {
      toggleChecked()
    }
  }
  
  func uncheck() {
    if checked {
      toggleChecked()
    }
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
    layer.borderColor = color?.cgColor
    layer.borderWidth = checked ? 0 : TGCAFilterButton.borderWidth

    UIView.performWithoutAnimation {
      animBlock()
      layoutIfNeeded()
    }
  }
  
}
