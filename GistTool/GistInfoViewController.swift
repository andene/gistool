//
//  GistInfoViewController.swift
//  GistTool
//
//  Created by Andreas Kihlberg on 2016-03-15.
//  Copyright © 2016 Oak. All rights reserved.
//

import Cocoa
import Quartz

class GistInfoViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    
    @IBOutlet weak var closeButton: FontAwesomeButton!
    @IBOutlet weak var descriptionLabel: NSTextField!
    @IBOutlet weak var dateLabel: NSTextField!
    @IBOutlet weak var filesTableView: NSTableView!
    
    var loader: GithubLoader!
    var loadedGist: Gist!
    
    override func viewDidLoad() {
        
        // Layer
        view.wantsLayer = true
        
        closeButton.updateTitle("\u{f00d}", fontSize: 22.0)
        
        setupTableView()
        
        
        if let gist = self.loadedGist {
            
            descriptionLabel.useLatoWithSize(14.0, bold: true)
            descriptionLabel.textColor = ViewController.getLightTextColor()
            descriptionLabel.stringValue = gist.gistDescription
            
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateStyle = NSDateFormatterStyle.LongStyle
            dateFormatter.timeStyle = .MediumStyle
            
            let created = dateFormatter.stringFromDate(gist.createdAt!)
            let updated = dateFormatter.stringFromDate(gist.updatedAt!)
            
            dateLabel.useLatoWithSize(10.0, bold: false)
            dateLabel.textColor = ViewController.getMediumTextColor()
            dateLabel.stringValue = "Created at \(created), Updated at \(updated)"
        }
        
    }
    
    override func keyDown(theEvent: NSEvent) {
        interpretKeyEvents([theEvent])
    }
    
    override func cancelOperation(sender: AnyObject?) {
        dismissController(sender)
    }
    
    // Setup stuff on table view
    func setupTableView() {
        filesTableView.setDataSource(self)
        filesTableView.setDelegate(self)
        filesTableView.rowHeight = 200.0
        filesTableView.target = self
        filesTableView.doubleAction = "gistTableViewDoubleClick:"
        filesTableView.backgroundColor = ViewController.getBackgroundColor()
        
    }
    
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        let file = loadedGist.files[row] 
        
        guard let filename = file["filename"] as? String
            
            else {
                return nil
        }
        
        
        if let cell = tableView.makeViewWithIdentifier("mainCell", owner: nil) as? GistInfoTableCell {
            cell.filenameLabel.stringValue = filename
            
            
            let titleFont = NSFont(name: "Lato", size: 13.0)
            
            
            let pstyle = NSMutableParagraphStyle()
            
            let attributedTitle = NSAttributedString(string: file.content, attributes: [
                NSForegroundColorAttributeName : ViewController.getMediumTextColor(),
                NSParagraphStyleAttributeName : pstyle,
                NSFontAttributeName: titleFont!
                
                ])
            
            cell.textView.textStorage?.appendAttributedString(attributedTitle)
            
            return cell
        }
        return nil
        
    }
    
    
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return loadedGist.files.count
    }
    
    
    override func viewWillAppear() {
        view.layer?.backgroundColor = ViewController.getBackgroundColor().CGColor
    }
    
    @IBAction func closeModal(sender: NSButton) {
        dismissController(sender)
    }
}
