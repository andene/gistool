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
    @IBOutlet weak var refreshButton: FontAwesomeButton!
    @IBOutlet weak var gistTableView: NSTableView!
    @IBOutlet weak var avatarImage: NSImageView!
    @IBOutlet weak var username: NSButton!
    
    var loader: GithubLoader!
    var gists: [NSDictionary]!
    var user: NSDictionary!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        // Layer
        view.wantsLayer = true
        
        
        self.avatarImage.layer?.cornerRadius = 20
        
        
        // Setup Github loader
        self.loader = GithubLoader()
        
        // Setup settings button
        settingsButton.updateTitle("\u{f013}", fontSize: CGFloat(22.0))
        
        // Setup refresh button
        refreshButton.updateTitle("\u{f021}", fontSize: CGFloat(22.0))
        
        // Setup GistTableView
        setupGistTableView()
        
        if self.loader.isAuthorized() {
            refreshButton.hidden = false
            
            loadGists()
            
            loader.requestUserdata() { user, error in
                if let githubUser = user {
                    print("Loaded user\(githubUser)")
                    
                    self.user = githubUser
                    self.setLoggedinName(githubUser["name"] as! String)
                    self.loadAvatarImage(githubUser["avatar_url"] as! String)
                }

            }
        } else {
            refreshButton.hidden = true
        }
    }
    
    override func viewDidAppear() {
        if !self.loader.isAuthorized() {
            try! openViewControllerWithLoader(self.loader, sender: nil)
        }
    }
    
    
    // Open user profile on github when clicking on username
    @IBAction func usernameClicked(sender: NSButton) {
        NSWorkspace.sharedWorkspace().openURL(NSURL(string: self.user["html_url"] as! String)!)
    }
    
    
    func setLoggedinName(name: String) {
        let buttonFont = NSFont(name: "Lato-Light", size: 13.0)
        self.username.font = buttonFont
        self.username?.title = name
    }
    
    
    func loadGists() {
        loader.requestGists() { gists, error in
            if let unwrappedgists = gists {
                self.gists = unwrappedgists
                self.reloadGistTableView()
            }
        }
    }
    
    func loadAvatarImage(imageURL: String) {
        let avatarURL = NSURL(string: imageURL)
        
        let session = NSURLSession.sharedSession()
        session.dataTaskWithURL(avatarURL!) { data, response, error in
            dispatch_async(dispatch_get_main_queue()) { () -> Void in
                guard let data = data where error == nil else { return }
                let image = NSImage(data: data)
                image!.size = NSSize(width: 30, height: 30)
                self.avatarImage.image = image
            }
        }.resume()
    }
    
    // Setup stuff on table view
    func setupGistTableView() {
        gistTableView.setDataSource(self)
        gistTableView.setDelegate(self)
        gistTableView.rowHeight = 50.0
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
        
        guard let _ = item["id"] as? String,
            let gistHtmlURL = item["html_url"] as? String,
            let description = item["description"] as? String,
            let createdAt = item["created_at"] as? String,
            let publicGist = item["public"] as? Bool
            else {
                return nil
            }
        
        if let cell = tableView.makeViewWithIdentifier("mainCell", owner: nil) as? GistTableCell {
            cell.titleLabel.stringValue = description
            cell.subtitleLabel.stringValue = createdAt
            cell.setGistUrl(NSURL(string: gistHtmlURL)!)
            
            if publicGist {
                cell.privateIcon.stringValue = "\u{f023}"
            }
            
            return cell
        }
        return nil
        
    }
    
    func gistTableViewDoubleClick(sender: AnyObject) {

        if let gistInfoViewController = storyboard?.instantiateControllerWithIdentifier("GistInfoView") as? GistInfoViewController {
            
            let selectedGist = self.gists[gistTableView.clickedRow]
            
            gistInfoViewController.loader = self.loader
            gistInfoViewController.loadedGist = selectedGist as! [String : AnyObject]
            
            self.presentViewControllerAsSheet(gistInfoViewController)

        }
    }
    
    
    
    var openController: NSWindowController?
    
    // Open the Github Loader in new Window
    func openViewControllerWithLoader(loader: GithubLoader, sender: NSButton?) throws {
        if let windowController = storyboard?.instantiateControllerWithIdentifier("SingleService") as? NSWindowController {
            if let singleServiceViewController = windowController.contentViewController as? SingleServiceViewController {
                singleServiceViewController.loader = loader
                
                self.presentViewControllerAsSheet(singleServiceViewController)
                
//                windowController.showWindow(sender)

                openController = windowController
                return
            }
            throw ServiceError.IncorrectViewControllerClass
        }
        throw ServiceError.NoViewController
    }
    
    

    @IBAction func authButtonClicked(sender: NSButton) {
        try! openViewControllerWithLoader(self.loader, sender: sender)
    }

    @IBAction func refreshGists(sender: FontAwesomeButton) {
        loadGists()
    }
}

