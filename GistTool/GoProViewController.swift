//
//  GoProViewController.swift
//  GistTool
//
//  Created by Andreas Kihlberg on 2016-03-25.
//  Copyright © 2016 Oak. All rights reserved.
//

import Cocoa

class GoProViewController: NSViewController {
    
    @IBOutlet weak var purchaseButton: NSButton!
    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var descriptionLabel: NSTextField!
    
    override func viewDidLoad() {
        
        titleLabel.useLatoWithSize(14, bold: true)
        titleLabel.stringValue = "Purchase Gist Tool Pro Edition"
        
        descriptionLabel.useLatoWithSize(13, bold: false)
    }
    
    @IBAction func purchase(sender: NSButton) {
        print("Purchased")
        
        let userDefaults = NSUserDefaults.standardUserDefaults()
        userDefaults.setBool(true, forKey: "isPro")
        
        
        NSNotificationCenter.defaultCenter().postNotificationName(GistToolPuchasedPro, object: [])
    }
}
