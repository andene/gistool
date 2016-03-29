//
//  FontAwesomeButton.swift
//  GistTool
//
//  Created by Andreas Kihlberg on 2016-03-14.
//  Copyright © 2016 Oak. All rights reserved.
//

import Cocoa

class FontAwesomeButton: NSButton {
    
    override func awakeFromNib() {
        super.awakeFromNib()
       
    }
    
    func updateTitle(title: String, fontSize: CGFloat) {
       
        let titleFont = NSFont(name: "FontAwesome", size: fontSize)
        
        let pstyle = NSMutableParagraphStyle()
        
        let attributedTitle = NSAttributedString(string: title, attributes: [
            NSForegroundColorAttributeName : ViewController.getMediumTextColor(),
            NSParagraphStyleAttributeName : pstyle,
            NSFontAttributeName: titleFont!
            
            ])
        
        self.attributedTitle = attributedTitle
    }
    
}
