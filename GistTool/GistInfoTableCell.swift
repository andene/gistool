//
//  GistInfoTableCell.swift
//  GistTool
//
//  Created by Andreas Kihlberg on 2016-03-18.
//  Copyright © 2016 Oak. All rights reserved.
//

import Cocoa

class GistInfoTableCell: NSTableCellView, NSUserNotificationCenterDelegate {

    @IBOutlet var filenameLabel: NSTextField!
    @IBOutlet var textView: NSTextView!
    @IBOutlet weak var fileScrollView: NSScrollView!
    @IBOutlet weak var copyButton: FontAwesomeButton!
    
    override func drawRect(dirtyRect: NSRect) {
        
    }
    
    override func awakeFromNib() {
        filenameLabel.useLatoWithSize(14.0, bold: true)
        filenameLabel.textColor = ViewController.getLightTextColor()

        textView.textColor = ViewController.getDarkTextColor()
        textView.textContainerInset = NSSize(width: 5, height: 10)
        
        copyButton.updateTitle("\u{f0c5}", fontSize: 16.0)
        
        
        fileScrollView.drawsBackground = true
        fileScrollView.backgroundColor = ViewController.getWhiteBackgroundColor()
        fileScrollView.wantsLayer = true
        

        
    }
    
    @IBAction func copyToClipboard(sender: FontAwesomeButton) {
        
        let pasteBoard = NSPasteboard.generalPasteboard()
        
        pasteBoard.clearContents()
        if let textStorage = textView.textStorage {
            
            let notification = NSUserNotification()
            notification.title = "Gist copied"
//            notification.informativeText = "The body of this Swift notification"
            
            let notificationCenter = NSUserNotificationCenter.defaultUserNotificationCenter()
            notificationCenter.delegate = self
            notificationCenter.deliverNotification(notification)
            
            pasteBoard.writeObjects([textStorage.string])
        }

        
    }
    
    func userNotificationCenter(center: NSUserNotificationCenter, shouldPresentNotification notification: NSUserNotification) -> Bool {
        return true
    }
}
