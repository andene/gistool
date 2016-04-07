//
//  EditableTextField.swift
//  GistTool
//
//  Created by Andreas Kihlberg on 2016-03-30.
//  Copyright © 2016 Oak. All rights reserved.
//

import Cocoa

class EditableTextField: NSTextField {
    
    
    override func becomeFirstResponder() -> Bool {
        let success = super.becomeFirstResponder()
        
        if success {
            if let textField = self.window?.fieldEditor(true, forObject: self) as? NSTextView {
                if textField.respondsToSelector(Selector("setInsertionPointColor:")) {
                    textField.setSelectedRange(NSRange(location: (textField.textStorage?.string.characters.count)!, length: 0))
                    textField.backgroundColor = ViewController.getBackgroundColor()
                    textField.insertionPointColor = ViewController.getLightTextColor()
                }
            }
        }
        
        return success
        
    }
    
}