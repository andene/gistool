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
            
            self.loader.requestSingleGist(gist.gistId) { gists, error in
                print("Loaded single gist done", gists)
            }
            
            
            
            descriptionLabel.useLatoWithSize(14.0, bold: true)
            descriptionLabel.textColor = ViewController.getLightTextColor()
            descriptionLabel.stringValue = gist.gistDescription
            
            let dateFormatter = NSDateFormatter()
            //dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"

            //dateFormatter.dateStyle = NSDateFormatterStyle.LongStyle
            //dateFormatter.timeStyle = .MediumStyle
            
           // let _ = dateFormatter.dateFromString(gist.createdAt)
            
            dateLabel.useLatoWithSize(10.0, bold: false)
            dateLabel.textColor = ViewController.getMediumTextColor()
            dateLabel.stringValue = "Created at \(gist.createdAt), Updated at \(gist.updatedAt)"
        }
        
    }
    
    // Setup stuff on table view
    func setupTableView() {
        filesTableView.setDataSource(self)
        filesTableView.setDelegate(self)
        filesTableView.rowHeight = 65.0
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
