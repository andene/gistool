//
//  FileTextView.swift
//  GistTool
//
//  Created by Andreas Kihlberg on 2016-03-24.
//  Copyright © 2016 Oak. All rights reserved.
//

import Cocoa

class FileTextView: NSTextView {
    
    override func drawRect(dirtyRect: NSRect) {
        
        
        self.drawsBackground = true
        self.backgroundColor = ViewController.getLighBackgroundColor()
        self.wantsLayer = true
        self.layer?.borderWidth = 0
        self.textColor = ViewController.getLightTextColor()
        
        
        if var textStorage = self.textStorage {
            
            let textRange = NSRange.init(location: 0, length: textStorage.length)
            textStorage.addAttribute(NSForegroundColorAttributeName, value: ViewController.getLightTextColor(), range: textRange)
            
        }
    }
    
}
