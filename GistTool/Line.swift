//
//  Line.swift
//  GistTool
//
//  Created by Andreas Kihlberg on 2016-03-24.
//  Copyright © 2016 Oak. All rights reserved.
//

import Cocoa
class Line: NSBox {
    override func drawRect(dirtyRect: NSRect) {
        
        
        self.wantsLayer = true
        self.setFrameSize(NSSize(width: ((self.window?.frame.width)! - 30), height: 1))
        self.needsDisplay = true
        self.layer?.backgroundColor = ViewController.getLighBackgroundColor().CGColor
        self.layer?.borderColor = ViewController.getLighBackgroundColor().CGColor
        self.boxType = NSBoxType.Separator
        self.borderType = NSBorderType.NoBorder
        
        
    }
}
