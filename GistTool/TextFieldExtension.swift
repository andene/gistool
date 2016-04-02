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
        let color = NSColor(calibratedRed: CGFloat(50.0/255), green: CGFloat(50.0/255), blue: CGFloat(50.0/255), alpha: 1)
        
        var fontName = "Lato"
        
        if bold {
            fontName = "Lato-Bold"
        }
        
        self.font = NSFont(name: fontName, size: fontSize)
        self.textColor = color
    }
    
}
