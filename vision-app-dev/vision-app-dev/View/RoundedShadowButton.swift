//
//  RoundedShadowButton.swift
//  vision-app-dev
//
//  Created by Soufiane Salouf on 3/7/18.
//  Copyright © 2018 Soufiane Salouf. All rights reserved.
//

import UIKit

class RoundedShadowButton: UIButton {

    override func awakeFromNib() {
        self.layer.shadowColor = UIColor.darkGray.cgColor
        self.layer.shadowRadius = 15
        self.layer.shadowOpacity = 0.75
        self.layer.cornerRadius = self.frame.height/2
    }

}
