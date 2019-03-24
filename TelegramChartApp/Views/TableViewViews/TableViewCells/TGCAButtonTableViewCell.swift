//
//  TGCAButtonTableViewCell.swift
//  TelegramChartApp
//
//  Created by Igor on 09/03/2019.
//  Copyright © 2019 Fedotov Igor. All rights reserved.
//

import UIKit

class TGCAButtonTableViewCell: UITableViewCell {
  @IBOutlet weak var button: UIButton!
  
  static let defaultReuseId = "buttonCell"
  
  var onClickHandler: (()->())?
  
  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }
  
  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
    
    // Configure the view for the selected state
  }
  @IBAction func onClick(_ sender: Any) {
    onClickHandler?()
  }
  
}
