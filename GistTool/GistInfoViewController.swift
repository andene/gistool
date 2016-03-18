//
//  GistInfoViewController.swift
//  GistTool
//
//  Created by Andreas Kihlberg on 2016-03-15.
//  Copyright © 2016 Oak. All rights reserved.
//

import Cocoa
import Quartz

class GistInfoViewController: NSViewController {
    
    @IBOutlet weak var closeButton: FontAwesomeButton!
    @IBOutlet weak var descriptionLabel: NSTextField!
    
    var loader: GithubLoader!
    var loadedGist: Gist!
    
    override func viewDidLoad() {
        
        // Layer
        view.wantsLayer = true
        
        closeButton.updateTitle("\u{f00d}", fontSize: 22.0)
        
        
        if let gist = self.loadedGist {
            print("\(gist)")
            
            descriptionLabel.useLatoWithSize(14.0, bold: true)
            descriptionLabel.textColor = ViewController.getLightTextColor()
            descriptionLabel.stringValue = gist.description
        }
        
    }
    
    
    override func viewWillAppear() {
        view.layer?.backgroundColor = ViewController.getBackgroundColor().CGColor
    }
    
    @IBAction func closeModal(sender: NSButton) {
        dismissController(sender)
    }
}
