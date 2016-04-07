//
//  GistInfoTableCell.swift
//  GistTool
//
//  Created by Andreas Kihlberg on 2016-03-18.
//  Copyright © 2016 Oak. All rights reserved.
//

import Cocoa

class GistInfoTableCell: NSTableCellView, NSUserNotificationCenterDelegate {

    @IBOutlet var filenameLabel: EditableTextField!
    @IBOutlet var textView: NSTextView!
    @IBOutlet weak var fileScrollView: NSScrollView!
    @IBOutlet weak var copyButton: FontAwesomeButton!
    @IBOutlet weak var deleteFileButton: FontAwesomeButton!
    
    var viewController: GistInfoViewController?
    var file: File!
    
    override func drawRect(dirtyRect: NSRect) {
        
    }
    
    override func awakeFromNib() {
        filenameLabel.useLatoWithSize(14.0, bold: true)
        filenameLabel.textColor = ViewController.getLightTextColor()
        filenameLabel.backgroundColor = ViewController.getBackgroundColor()
        filenameLabel.focusRingType = NSFocusRingType.None
        
        
        textView.textColor = ViewController.getLightTextColor()
        textView.textContainerInset = NSSize(width: 10, height: 10)
        
        copyButton.updateTitle("\u{f0c5}", fontSize: 16.0)
        deleteFileButton.updateTitle("\u{f014}", fontSize: 16.0)
        
    }
    @IBAction func deleteFile(sender: AnyObject) {
        if let vc = self.viewController {
            
            vc.deleteFile(self.file)
        }
    }
    
    @IBAction func copyToClipboard(sender: FontAwesomeButton) {
        
        let pasteBoard = NSPasteboard.generalPasteboard()
        
        pasteBoard.clearContents()
        if let textStorage = textView.textStorage {
            
            let notification = NSUserNotification()
            notification.title = "Gist copied"
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
