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
            
            ViewController.getLighBackgroundColor().setFill()
            NSRectFill(dirtyRect)
        }
    }
    
}
