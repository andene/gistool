//
//  GistTableRow.swift
//  GistTool
//
//  Created by Andreas Kihlberg on 2016-03-14.
//  Copyright © 2016 Oak. All rights reserved.
//

import Cocoa

class GistTableRow: NSTableRowView {
    
    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)
        
        self.layer?.cornerRadius = 10.0
        
        if selected {
            
            NSColor(calibratedRed: CGFloat(240.0/255), green: CGFloat(240.0/255), blue: CGFloat(240.0/255), alpha: 1).setFill()
            NSRectFill(dirtyRect)
        }
    }
    
}
