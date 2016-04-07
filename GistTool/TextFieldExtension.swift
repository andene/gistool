//
//  TextFieldExtension.swift
//  GistTool
//
//  Created by Andreas Kihlberg on 2016-03-16.
//  Copyright © 2016 Oak. All rights reserved.
//

import Cocoa

extension NSTextField {
    
    
    func useLatoWithSize(fontSize: CGFloat, bold: Bool) {
        
        var fontName = "Lato"
        
        if bold {
            fontName = "Lato-Bold"
        }
        
        self.font = NSFont(name: fontName, size: fontSize)
        self.textColor = ViewController.getDarkTextColor()
    }
    
}
