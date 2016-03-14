//
//  gistTableCell.swift
//  GistTool
//
//  Created by Andreas Kihlberg on 2016-03-13.
//  Copyright © 2016 Oak. All rights reserved.
//


import Cocoa

class GistTableCell: NSTableCellView {

    @IBOutlet var titleLabel: NSTextField!
    @IBOutlet var subtitleLabel: NSTextField!
    @IBOutlet var linkButton: FontAwesomeButton!
    
    var gistURL: NSURL?
    
    func setGistUrl(url: NSURL) {
        gistURL = url
    }
    
    override func awakeFromNib() {
        linkButton.updateTitle("\u{f08e}", fontSize: CGFloat(12.0))
    }
    
    @IBAction func visitGistURL(sender: AnyObject) {
        NSWorkspace.sharedWorkspace().openURL(gistURL!)
    }
    
    override func drawRect(dirtyRect: NSRect) {
    
        let titleColor = NSColor(calibratedRed: CGFloat(30.0/255), green: CGFloat(30.0/255), blue: CGFloat(30.0/255), alpha: 1)
        let titleFont = NSFont(name: "Lato-Bold", size: 13.0)
        titleLabel.textColor = titleColor
        titleLabel.font = titleFont
        
        let subtitleColor = NSColor(calibratedRed: CGFloat(125.0/255), green: CGFloat(125.0/255), blue: CGFloat(125.0/255), alpha: 1)
        let subtitleFont = NSFont(name: "Lato-Light", size: 11.0)
        subtitleLabel.textColor = subtitleColor
        subtitleLabel.font = subtitleFont
        
    }
}