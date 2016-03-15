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
    
    var loader: GithubLoader!
    var loadedGist: [String: AnyObject]!
    
    override func viewDidLoad() {
        
        // Layer
        view.wantsLayer = true
        
        closeButton.updateTitle("\u{f00d}", fontSize: 22.0)
        
        if let gist = self.loadedGist {
            print("\(gist)")
        }
        
    }
    
    
    override func viewWillAppear() {
        view.layer?.backgroundColor = NSColor.whiteColor().CGColor
    }
    
    @IBAction func closeModal(sender: NSButton) {
        dismissController(sender)
    }
}
