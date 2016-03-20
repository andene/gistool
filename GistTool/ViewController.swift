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
    @IBOutlet weak var hLine: NSBox!
    @IBOutlet weak var searchField: NSSearchField!
    @IBOutlet weak var searchFieldCell: NSSearchFieldCell!
    
    var loader: GithubLoader!
    var gists: [Gist]!
    var searchResults: [Gist]!
    var user: NSDictionary!
    var darkThemeEnabled:Bool!
    
    static func getBackgroundColor() -> NSColor {
        return NSColor(calibratedRed: CGFloat(20.0/255), green: CGFloat(21.0/255), blue: CGFloat(20.0/255), alpha: 1.0)
    }
    
    static func getLighBackgroundColor() -> NSColor {
        return NSColor(calibratedRed: CGFloat(40.0/255), green: CGFloat(40.0/255), blue: CGFloat(40.0/255), alpha: 1.0)
    }
    static func getLightTextColor() -> NSColor {
        return NSColor(calibratedRed: CGFloat(240.0/255), green: CGFloat(240.0/255), blue: CGFloat(240.0/255), alpha: 1)
    }
    static func getMediumTextColor() -> NSColor {
        return NSColor(calibratedRed: CGFloat(150.0/255), green: CGFloat(150.0/255), blue: CGFloat(150.0/255), alpha: 1)
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        let userDefault = NSUserDefaults.standardUserDefaults()
        if let useDarkTheme = userDefault.boolForKey("darkTheme") as? Bool{
            darkThemeEnabled = useDarkTheme
        }
        
        // Layer
        view.wantsLayer = true
        
        
        self.avatarImage.layer?.cornerRadius = 20
        
        // Search field
        setupSearchField()


        
        // Setup Github loader
        self.loader = GithubLoader()
        
        // Setup settings button
        settingsButton.updateTitle("\u{f013}", fontSize: CGFloat(22.0))
        
        // Setup refresh button
        refreshButton.updateTitle("\u{f021}", fontSize: CGFloat(22.0))
        
        // Setup GistTableView
        setupGistTableView()
       
        //hLine.boxType = NSBoxType.Custom
        //hLine.borderType = NSBorderType.LineBorder
        //hLine.borderColor = NSColor(calibratedRed: CGFloat(240/255), green: CGFloat(240/255), blue: CGFloat(240/255), alpha: 1)
        
        if self.loader.isAuthorized() {
            isSignedIn()
        
        } else {
            refreshButton.hidden = true
        }
    }
    
    func isSignedIn() {
        
        refreshButton.hidden = false
        
        loadGists()
        
        loader.requestUserdata() { user, error in
            if let githubUser = user {
                
                self.user = githubUser
                self.setLoggedinName(githubUser["name"] as! String)
                self.loadAvatarImage(githubUser["avatar_url"] as! String)
            }
        }
    }
    
    func isSignedOut() {
        
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
    
    
    func setupSearchField() {
        searchField.sendsSearchStringImmediately = true
        searchField.drawsBackground = true
        searchField.backgroundColor = ViewController.getLighBackgroundColor()
        searchField.textColor = ViewController.getMediumTextColor()
        searchField.font = NSFont(name: "Lato", size: 12.0)
    }
    
    func setLoggedinName(name: String) {
        let buttonFont = NSFont(name: "Lato-Light", size: 13.0)
        let pstyle = NSMutableParagraphStyle()
        
        let attributedTitle = NSAttributedString(string: name, attributes: [
            NSForegroundColorAttributeName : ViewController.getLightTextColor(),
            NSParagraphStyleAttributeName : pstyle,
            NSFontAttributeName: buttonFont!
            
        ])
        
        username.attributedTitle = attributedTitle
    }
    
    func searchInGists(query:String?=nil) {
        
        if let searchQuery = query {
            let searchDescription = NSPredicate(format: "SELF.gistDescription CONTAINS[c] %@", searchQuery)
            let searchFilename = NSPredicate(format: "SELF.firstFilename CONTAINS[c] %@", searchQuery)
            
            let searchCompound = NSCompoundPredicate(type: NSCompoundPredicateType.OrPredicateType, subpredicates: [searchDescription, searchFilename])

            self.searchResults = self.gists.filter() { searchCompound.evaluateWithObject($0) }
        } else {
            self.searchResults = self.gists
        }
        self.reloadGistTableView()

    }
    
    func loadGists() {
        
        loader.requestGists() { gists, error in
            if let unwrappedgists = gists {
                self.gists = unwrappedgists
                self.searchResults = unwrappedgists
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
        gistTableView.rowHeight = 65.0
        gistTableView.target = self
        gistTableView.doubleAction = "gistTableViewDoubleClick:"
        gistTableView.backgroundColor = ViewController.getBackgroundColor()
        
    }

    override func viewWillAppear() {
        let backgroundColor = ViewController.getBackgroundColor()
        view.layer?.backgroundColor = backgroundColor.CGColor
    }
    
    
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        if let gists = self.searchResults {
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
    
        guard let gist = self.searchResults?[row] else {
            return nil
        }
        
        if let cell = tableView.makeViewWithIdentifier("mainCell", owner: nil) as? GistTableCell {
            cell.titleLabel.stringValue = gist.firstFilename //description
            cell.subtitleLabel.stringValue = gist.createdAt
            cell.setGistUrl(NSURL(string: gist.htmlUrl)!)
            cell.descriptionLabel.stringValue = gist.gistDescription
            
            if (gist.isPublic) {
                cell.privateIcon.stringValue = "\u{f023}"
            }
            
            return cell
        }
        return nil
        
    }

    func gistTableViewDoubleClick(sender: AnyObject) {

        if let gistInfoViewController = storyboard?.instantiateControllerWithIdentifier("GistInfoView") as? GistInfoViewController {
            
            let selectedGist = self.searchResults[gistTableView.clickedRow] as Gist!
            
            gistInfoViewController.loader = self.loader
            gistInfoViewController.loadedGist = selectedGist
            
            self.presentViewControllerAsSheet(gistInfoViewController)

        }
    }
    
    
    
    @IBAction func didSearch(sender: NSSearchField) {
        let searchQuery = sender.stringValue
        
        if searchQuery.characters.count > 0 {
            searchInGists(sender.stringValue)
        } else {
            searchInGists()
        }
    }
    
    
    // Open the Github Loader in new Window
    func openViewControllerWithLoader(loader: GithubLoader, sender: NSButton?) throws {
        if let windowController = storyboard?.instantiateControllerWithIdentifier("SingleService") as? NSWindowController {
            if let singleServiceViewController = windowController.contentViewController as? SingleServiceViewController {

                singleServiceViewController.loader = loader
                
                view.window?.beginSheet(singleServiceViewController.view.window!, completionHandler: { responseCode in
                    if responseCode == NSModalResponseOK {
                        self.isSignedIn()
                    }

                })
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

