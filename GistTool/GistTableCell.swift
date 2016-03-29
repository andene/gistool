//
//  gistTableCell.swift
//  GistTool
//
//  Created by Andreas Kihlberg on 2016-03-13.
//  Copyright © 2016 Oak. All rights reserved.
//


import Cocoa
import Quartz

class GistTableCell: NSTableCellView {

    @IBOutlet var titleLabel: NSTextField!
    @IBOutlet var subtitleLabel: NSTextField!
    @IBOutlet var linkButton: FontAwesomeButton!
    @IBOutlet var privateIcon: NSTextField!
    @IBOutlet var descriptionLabel: NSTextField!
    
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
    
        
        let titleFont = NSFont(name: "Lato-Bold", size: 14.0)
        titleLabel.textColor = ViewController.getLightTextColor()
        titleLabel.font = titleFont
        titleLabel.sizeToFit()
        
        let subtitleFont = NSFont(name: "Lato-Light", size: 11.0)
        subtitleLabel.textColor = ViewController.getMediumTextColor()
        subtitleLabel.font = subtitleFont
        
        
        let descriptionFont = NSFont(name: "Lato-Light", size: 13.0)
        descriptionLabel.textColor = ViewController.getLightTextColor()
        descriptionLabel.font = descriptionFont
        
        
        let iconFont = NSFont(name: "FontAwesome", size: 13.0)
        privateIcon.textColor = ViewController.getMediumTextColor()
        privateIcon.font = iconFont
        
        
        let height = self.bounds.height - 1
        let width = self.bounds.width
        let line = NSView(frame: CGRect(x: 0, y: height, width: width, height: 1))
        line.wantsLayer = true
        line.layer?.backgroundColor = ViewController.getLighBackgroundColor().CGColor

        self.addSubview(line)
        
        
//        UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0, 200, self.view.bounds.size.width, 1)];
 //       lineView.backgroundColor = [UIColor blackColor];
  //      [self.view addSubview:lineView];
   //     [lineView release];
        
    }
}