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
       
        let fontColor = NSColor(calibratedRed: CGFloat(30.0/255), green: CGFloat(30.0/255), blue: CGFloat(30.0/255), alpha: 1)
        let titleFont = NSFont(name: "FontAwesome", size: fontSize)
        
        
        let pstyle = NSMutableParagraphStyle()
        
        let attributedTitle = NSAttributedString(string: title, attributes: [
            NSForegroundColorAttributeName : fontColor,
            NSParagraphStyleAttributeName : pstyle,
            NSFontAttributeName: titleFont!
            
            ])
        
        self.attributedTitle = attributedTitle
    }
    
}
