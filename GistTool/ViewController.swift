//
//  ViewController.swift
//  GistTool
//
//  Created by Andreas Kihlberg on 2016-03-08.
//  Copyright © 2016 Oak. All rights reserved.
//

import Cocoa
import Quartz

let OAuth2AppDidReceiveCallbackNotification = "OAuth2AppDidReceiveCallback"


enum ServiceError: ErrorType {
    case NoViewController
    case IncorrectViewControllerClass
}


class ViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {

    
    @IBOutlet weak var settingsButton: FontAwesomeButton!
    @IBOutlet weak var gistTableView: NSTableView!
    var loader: GithubLoader!
    var gists: [NSDictionary]!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        // Layer
        view.wantsLayer = true
        
        
        // Setup Github loader
        self.loader = GithubLoader()
        
        // Setup settings button
        settingsButton.updateTitle("\u{f013}", fontSize: CGFloat(22.0))
        
        // Setup GistTableView
        setupGistTableView()
        
        if self.loader.isAuthorized() {
            loader.requestGists() { gists, error in
                if let unwrappedgists = gists {
                    self.gists = unwrappedgists
                    self.reloadGistTableView()
                }
            }
        }
    }
    
    
    // Setup stuff on table view
    func setupGistTableView() {
        gistTableView.setDataSource(self)
        gistTableView.setDelegate(self)
        gistTableView.rowHeight = 60.0
        gistTableView.target = self
        gistTableView.doubleAction = "gistTableViewDoubleClick:"
        
    }

    override func viewWillAppear() {
        view.layer?.backgroundColor = NSColor.whiteColor().CGColor
    }
    
    
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        if let gists = self.gists {
            return gists.count
        }
        return 0
    }
    
    func reloadGistTableView() -> Void {
        gistTableView.reloadData()
    }
    
    func tableView(tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        let tableRow = GistTableRow()
        return tableRow
    }
    
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
    
        guard let item = self.gists?[row] else {
            return nil
        }
        
        guard let gistId = item["id"] as? String,
            let gistHtmlURL = item["html_url"] as? String,
            let description = item["description"] as? String
            else {
                return nil
            }
        
        if let cell = tableView.makeViewWithIdentifier("mainCell", owner: nil) as? GistTableCell {
            cell.titleLabel.stringValue = description
            cell.subtitleLabel.stringValue = gistId
            cell.setGistUrl(NSURL(string: gistHtmlURL)!)
            
            return cell
        }
        return nil
        
    }
    
    func gistTableViewDoubleClick(sender: AnyObject) {
        
        print("did Double click")
        print("Click row \(gistTableView.clickedRow) clicked column \(gistTableView.clickedColumn)")
        
    }
    
    
    
    var openController: NSWindowController?
    
    // Open the Github Loader in new Window
    func openViewControllerWithLoader(loader: GithubLoader, sender: NSButton?) throws {
        if let windowController = storyboard?.instantiateControllerWithIdentifier("SingleService") as? NSWindowController {
            if let singleServiceViewController = windowController.contentViewController as? SingleServiceViewController {
                singleServiceViewController.loader = loader
                
                windowController.showWindow(sender)
                openController = windowController
                return
            }
            throw ServiceError.IncorrectViewControllerClass
        }
        throw ServiceError.NoViewController
    }
    
    

    @IBAction func authButtonClicked(sender: NSButton) {
        try! openViewControllerWithLoader(self.loader, sender: sender)
        
        print("Clicked: \(sender)")
    }

}

