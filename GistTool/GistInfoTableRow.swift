//
//  GistTableRow.swift
//  GistTool
//
//  Created by Andreas Kihlberg on 2016-03-14.
//  Copyright © 2016 Oak. All rights reserved.
//

import Cocoa

class GistInfoTableRow: NSTableRowView {
    
    
    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)
        
        if selected {
            
            ViewController.getBackgroundColor().setFill()
            NSRectFill(dirtyRect)
        }
    }
    
}
