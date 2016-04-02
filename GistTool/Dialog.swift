//
//  Dialog.swift
//  GistTool
//
//  Created by Andreas Kihlberg on 2016-03-31.
//  Copyright © 2016 Oak. All rights reserved.
//

import Cocoa

class Dialog {
    
    class func dialogOKCancel(question: String, text: String) -> Bool {
        let myPopup: NSAlert = NSAlert()
        myPopup.messageText = question
        myPopup.informativeText = text
        myPopup.alertStyle = NSAlertStyle.WarningAlertStyle
        myPopup.addButtonWithTitle("OK")
        myPopup.addButtonWithTitle("Cancel")
        let res = myPopup.runModal()
        if res == NSAlertFirstButtonReturn {
            return true
        }
        return false
    }
}
