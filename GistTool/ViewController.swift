//
//  ViewController.swift
//  GistTool
//
//  Created by Andreas Kihlberg on 2016-03-08.
//  Copyright © 2016 Oak. All rights reserved.
//

import Cocoa
import Quartz
import RealmSwift

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
    var gists: Results<Gist>!
    var realm: Realm
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
    

    required init?(coder: NSCoder) {
        
        let config = Realm.Configuration(
            schemaVersion: 2,
            
            migrationBlock: { migration, oldSchemaVersion in
                if (oldSchemaVersion < 2) {
                }
        })
        
        Realm.Configuration.defaultConfiguration = config

        self.realm = try! Realm()
        
        super.init(coder: coder)
    }

    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        // Setup realm
        self.realm = try! Realm()
        
        
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
    
    func setupRealmConfiguration() {
        let config = Realm.Configuration(
            schemaVersion: 1,
            
            migrationBlock: { migration, oldSchemaVersion in
                if (oldSchemaVersion < 1) {
                }
        })
        
        Realm.Configuration.defaultConfiguration = config
        
        
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
            let fileSearch = NSPredicate(format: "ANY SELF.files.content CONTAINS[c] %@", searchQuery)
            
            let searchCompound = NSCompoundPredicate(type: NSCompoundPredicateType.OrPredicateType, subpredicates: [searchDescription, searchFilename, fileSearch])
            self.gists = self.realm.objects(Gist).filter(searchCompound).sorted("updatedAt", ascending: false)
            
        } else {
            self.gists = self.realm.objects(Gist).sorted("updatedAt", ascending: false)
        }
        self.reloadGistTableView()

    }
    
    func loadGists() {
     
        loader.requestGists() { gists, error in
            self.gists = self.realm.objects(Gist).sorted("updatedAt", ascending: false)
            self.reloadGistTableView()
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
    
        guard let gist = self.gists?[row] else {
            return nil
        }
        
        if let cell = tableView.makeViewWithIdentifier("mainCell", owner: nil) as? GistTableCell {
            
            var title:String
            
            if gist.files.count > 1 {
                title = "\(gist.firstFilename) and \(gist.files.count - 1) more"
            } else {
                title = gist.firstFilename
            }
            
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateStyle = NSDateFormatterStyle.LongStyle
            dateFormatter.timeStyle = .MediumStyle
            
            // let _ = dateFormatter.dateFromString(gist.createdAt)
            
            cell.titleLabel.stringValue = title
            cell.subtitleLabel.stringValue = "Updated \(dateFormatter.stringFromDate(gist.updatedAt!))"
            cell.setGistUrl(NSURL(string: gist.htmlUrl)!)
            cell.descriptionLabel.stringValue = gist.gistDescription
            
            if (gist.isGistPublic) {
                cell.privateIcon.stringValue = "\u{f023}"
            }
            
            return cell
        }
        return nil
        
    }

    override func keyDown(theEvent: NSEvent) {
        interpretKeyEvents([theEvent])
    }
    
    override func insertNewline(sender: AnyObject?) {
        print("Pressed enter")
        openGistInfor(gistTableView.selectedRow)
    }
    
    func gistTableViewDoubleClick(sender: AnyObject) {
        openGistInfor(gistTableView.clickedRow)
    }
    
    
    /*
    * Open a sheet with Gist information
    * @param {int} row The current selected row in tableview
    */
    func openGistInfor(row: Int) {
        
        if let gistInfoViewController = storyboard?.instantiateControllerWithIdentifier("GistInfoView") as? GistInfoViewController {
            let selectedGist = self.gists[row] as Gist!
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

