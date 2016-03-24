//
//  GistInfoTableCell.swift
//  GistTool
//
//  Created by Andreas Kihlberg on 2016-03-18.
//  Copyright © 2016 Oak. All rights reserved.
//

import Cocoa

class GistInfoTableCell: NSTableCellView {

    @IBOutlet var filenameLabel: NSTextField!
    @IBOutlet var textView: NSTextView!
    @IBOutlet weak var fileScrollView: NSScrollView!
    @IBOutlet weak var copyButton: FontAwesomeButton!
    
    override func drawRect(dirtyRect: NSRect) {
        
    }
    
    override func awakeFromNib() {
        filenameLabel.useLatoWithSize(13.0, bold: true)
        filenameLabel.textColor = ViewController.getLightTextColor()

        textView.textColor = ViewController.getLightTextColor()
        textView.textContainerInset = NSSize(width: 5, height: 10)
        
        copyButton.updateTitle("\u{f0c5}", fontSize: 13.0)
        
        
        fileScrollView.drawsBackground = true
        fileScrollView.backgroundColor = ViewController.getLighBackgroundColor()
        fileScrollView.wantsLayer = true
        fileScrollView.layer?.cornerRadius = 10.0
        

        
    }
    
    @IBAction func copyToClipboard(sender: FontAwesomeButton) {
        
        let pasteBoard = NSPasteboard.generalPasteboard()
        
        pasteBoard.clearContents()
        if let textStorage = textView.textStorage {
            pasteBoard.writeObjects([textStorage.string])
        }

        
    }
}
