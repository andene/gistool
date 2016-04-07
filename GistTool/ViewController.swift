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
let GistToolPuchasedPro = "GistToolPuchasedPro"
let OpenGoProNotification = "openGoProWindow"
let OpenSettingsNotification = "openSettings"
let DarkThemeChangedNotification = "darkThemeChanged"

enum ServiceError: ErrorType {
    case NoViewController
    case IncorrectViewControllerClass
}


class ViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate, GistInfoControllerDelegate {

    
    @IBOutlet weak var settingsButton: FontAwesomeButton!
    @IBOutlet weak var refreshButton: FontAwesomeButton!
    @IBOutlet weak var newButton: FontAwesomeButton!
    @IBOutlet weak var gistTableView: NSTableView!
    @IBOutlet weak var avatarImage: NSImageView!
    @IBOutlet weak var username: NSButton!
    @IBOutlet weak var hLine: NSBox!
    @IBOutlet weak var searchField: NSSearchField!
    @IBOutlet weak var searchFieldCell: NSSearchFieldCell!
    @IBOutlet weak var spinner: NSProgressIndicator!
    
    var loader: GithubLoader!
    var gists: Results<Gist>!
    var realm: Realm
    var user: NSDictionary!
    var darkThemeEnabled:Bool!
    var userDefaults = NSUserDefaults.standardUserDefaults()
    var goProWindow: NSWindowController?
    var goProView: GoProViewController?
    
    static func getBackgroundColor() -> NSColor {
        let userDefault = NSUserDefaults.standardUserDefaults()

        if userDefault.boolForKey("darkTheme") {
            return NSColor(calibratedRed: CGFloat(20.0/255), green: CGFloat(21.0/255), blue: CGFloat(20.0/255), alpha: 1.0)
        } else {
            return NSColor(calibratedRed: CGFloat(250.0/255), green: CGFloat(250.0/255), blue: CGFloat(250.0/255), alpha: 1.0)
        }
        
        
    }
    
    static func getLighBackgroundColor() -> NSColor {
        if NSUserDefaults.standardUserDefaults().boolForKey("darkTheme") {
            return NSColor(calibratedRed: CGFloat(40.0/255), green: CGFloat(40.0/255), blue: CGFloat(40.0/255), alpha: 1.0)
        } else {
            return NSColor(calibratedRed: CGFloat(210.0/255), green: CGFloat(210.0/255), blue: CGFloat(210.0/255), alpha: 1.0)
        }
        
    }
    static func getLightTextColor() -> NSColor {
        if NSUserDefaults.standardUserDefaults().boolForKey("darkTheme") {
            return NSColor(calibratedRed: CGFloat(240.0/255), green: CGFloat(240.0/255), blue: CGFloat(240.0/255), alpha: 1)
        } else {
            return NSColor(calibratedRed: CGFloat(30/255), green: CGFloat(30.0/255), blue: CGFloat(30.0/255), alpha: 1)
        }
        
    }
    static func getMediumTextColor() -> NSColor {
        return NSColor(calibratedRed: CGFloat(150.0/255), green: CGFloat(150.0/255), blue: CGFloat(150.0/255), alpha: 1)
    }
    static func getDarkTextColor() -> NSColor {
        
        if NSUserDefaults.standardUserDefaults().boolForKey("darkTheme") {
            return NSColor(calibratedRed: CGFloat(200.0/255), green: CGFloat(200.0/255), blue: CGFloat(200.0/255), alpha: 1)
        } else {
            return NSColor(calibratedRed: CGFloat(50/255), green: CGFloat(50.0/255), blue: CGFloat(50.0/255), alpha: 1)
        }
        
        
    }
    static func getWhiteBackgroundColor() -> NSColor {
        return NSColor(calibratedRed: CGFloat(240.0/255), green: CGFloat(240.0/255), blue: CGFloat(240.0/255), alpha: 1)
    }
    

    required init?(coder: NSCoder) {
        
        let config = Realm.Configuration(
            schemaVersion: 3,
            
            migrationBlock: { migration, oldSchemaVersion in
                if (oldSchemaVersion < 3) {
                }
        })
        
        Realm.Configuration.defaultConfiguration = config

        self.realm = try! Realm()

        super.init(coder: coder)
    }

    
    
    override func viewDidLoad() {
        
        
        //let userDefaults = NSUserDefaults.standardUserDefaults()
        //userDefaults.setBool(false, forKey: "isPro")
        
        let fontManager = FontManager()
        fontManager.loadFont("fontawesome-webfont", fontExtension: "ttf")
        fontManager.loadFont("Lato-Regular", fontExtension: "ttf")
        fontManager.loadFont("Lato-Bold", fontExtension: "ttf")
        fontManager.loadFont("Lato-Light", fontExtension: "ttf")
        
        super.viewDidLoad()
        
        // Setup realm
        self.realm = try! Realm()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.handlePurchasedPro), name: GistToolPuchasedPro, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.authButtonClicked), name: OpenSettingsNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.openGoProWindowController), name: OpenGoProNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.darkthemeToggled), name: DarkThemeChangedNotification, object: nil)
        
        
        // Clean up any temporary gists created in database
        cleanupTemporaryRecordsInDatabase()
        
        let _ = userDefaults.boolForKey("darkTheme")
        
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
        
        // Setup create button
        newButton.updateTitle("\u{f067}", fontSize: CGFloat(22.0))
        
        
        
        setupElements()
        
        setupSpinner()
       
        updateLoginStatus()
    }
    
    func setupElements() {
        // Setup GistTableView
        setupGistTableView()
        setupBackground()
        
        hLine.hidden = true
        hLine.hidden = false
    }
    
    func darkthemeToggled() {
        setupElements()
        reloadGistTableView()
    }
    
    func cleanupTemporaryRecordsInDatabase() {
        
        if let tempGist = realm.objects(Gist).filter("gistId = %@", Gist.temporaryGistId).first {
            try! realm.write {
                for file in tempGist.files {
                    realm.delete(file)
                }
            }
            
            try! self.realm.write() {
                realm.delete(tempGist)
            }
        }
        
        
    }
    
    func updateLoginStatus() {
        if self.loader.isAuthorized() {
            isSignedIn()
        } else {
            isSignedOut()
        }
    }
    
    func isSignedIn() {
        refreshButton.hidden = false
        newButton.hidden = false
        loadGists()
        loader.requestUserdata() { user, error in
            if let githubUser = user {
                print("\(githubUser)")
                self.user = githubUser
                self.setLoggedinName(githubUser["login"] as! String)
                self.loadAvatarImage(githubUser["avatar_url"] as! String)
            }
        }
    }
    
    func isSignedOut() {
        refreshButton.hidden = true
        newButton.hidden = true
        
        if let _ = self.user {
            self.user = nil
        }


        self.setLoggedinName("Not authorized")
        self.avatarImage.hidden = true
        loadGists()
    }
    
    func getURLForUser() -> String? {
        if let userURL = self.user?["html_url"] as? String {
            return userURL
        } else {
            return nil
        }
    }
    
    override func viewDidAppear() {
        if !self.loader.isAuthorized() {
            try! openViewControllerWithLoader(self.loader, sender: nil)
        }
    }
    
    
    // Open user profile on github when clicking on username
    @IBAction func usernameClicked(sender: NSButton) {
        if let userURL = getURLForUser() as String? {
            NSWorkspace.sharedWorkspace().openURL(NSURL(string: userURL)!)
        }

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
        searchField.wantsLayer = true
        searchField.drawsBackground = true
        searchField.backgroundColor = ViewController.getLighBackgroundColor()
        searchField.textColor = ViewController.getMediumTextColor()
        searchField.font = NSFont(name: "Lato", size: 12.0)
    }
    
    func setLoggedinName(name: String) {
        let buttonFont = NSFont(name: "Lato-Light", size: 13.0)
        let pstyle = NSMutableParagraphStyle()
        
        let attributedTitle = NSAttributedString(string: name, attributes: [
            NSForegroundColorAttributeName : ViewController.getMediumTextColor(),
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
    
    func setupSpinner() {
        spinner.style = NSProgressIndicatorStyle.SpinningStyle
    }
    
    func loadGists() {
        spinner.startAnimation([])
        loader.requestGists() { gists, error in
            self.gists = self.realm.objects(Gist).sorted("updatedAt", ascending: false)
            self.reloadGistTableView()
            self.spinner.stopAnimation([])
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
                self.avatarImage.hidden = false
                self.avatarImage.image = image
            }
        }.resume()
    }
    
    // Setup stuff on table view
    func setupGistTableView() {
        gistTableView.setDataSource(self)
        gistTableView.setDelegate(self)
        gistTableView.rowHeight = 75.0
        gistTableView.target = self
        gistTableView.doubleAction = "gistTableViewDoubleClick:"
        gistTableView.backgroundColor = ViewController.getBackgroundColor()
        
    }

    func setupBackground() {
        let backgroundColor = ViewController.getBackgroundColor()
        view.layer?.backgroundColor = backgroundColor.CGColor
    }
    override func viewWillAppear() {
        setupBackground()
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
            
            if (!gist.isGistPublic) {
                cell.privateIcon.stringValue = "\u{f023}"
            }
            
            return cell
        }
        return nil
        
    }

    //MARK - Key events
    
    /*
    * Handle keyDown events and pass it to interpretKeyEvents function
    */
    override func keyDown(theEvent: NSEvent) {
        interpretKeyEvents([theEvent])
    }
    
    
    /*
    * When users presses enter in the table view
    */
    override func insertNewline(sender: AnyObject?) {
        let selectedRow = gistTableView.selectedRow;
        if selectedRow >= 0 {
            let gist = getGistForRow(gistTableView.selectedRow)
            openGistInfo(gist)
        }
    }
    
    override func deleteBackward(sender: AnyObject?) {
        let selectedRow = gistTableView.selectedRow;
        if selectedRow >= 0 {
            
            if Dialog.dialogOKCancel("Delete Gist", text: "Are you sure you want to delete this Gist? ") {
            
                let gist = getGistForRow(selectedRow)
                
                loader.deleteGist(gist) { statusCode, error in
                    // Successfully removed gist from github, just in case remove from Realm
                    if error != nil {
                        Dialog.showError("An error occured", text: "Could not delete Gist")
                    } else if statusCode! == 204  {
                        gist.deleteGistAndFiles()
                        self.loadGists()
                    } else if statusCode == 404 {
                        // Gist not found on github so just delete the local file
                        gist.deleteGistAndFiles()
                    } else {
                    }
                }
            }
        }
    }
    
    
    /*
    * User double clicks a row in table view
    */
    func gistTableViewDoubleClick(sender: AnyObject) {
        let gist = getGistForRow(gistTableView.clickedRow)
        openGistInfo(gist)
    }
    
    
    /*
    * Get a Gist object from index in tableview
    * @param {Int} row Which row index in gistTableView
    * @return Gist
    */
    func getGistForRow(row: Int) -> Gist {
        let selectedGist = self.gists[row] as Gist!
        return selectedGist
    }
    
    
    
    /*
    * Open a sheet with Gist information
    * @param {int} row The current selected row in tableview
    */
    
    func openGistInfo(gist: Gist) {
        
        if let gistInfoViewController = storyboard?.instantiateControllerWithIdentifier("GistInfoView") as? GistInfoViewController {

            gistInfoViewController.loader = loader
            gistInfoViewController.delegate = self
            gistInfoViewController.loadedGist = gist
            self.presentViewControllerAsSheet(gistInfoViewController)
            
        }
    }
    
    
    /*
    * Delegate method called when user updated a Gist
    */
    func didUpdateGist(gistDictionary: NSDictionary) {
        loadGists()
    }
    
    
    /*
    * Action sent from search form
    */
    
    @IBAction func didSearch(sender: NSSearchField) {
        let searchQuery = sender.stringValue
        
        if !userDefaults.boolForKey("isPro") && searchQuery.characters.count > 0 {
            openGoProWindowController(sender)
        } else {
    
            
            if searchQuery.characters.count > 0 {
                searchInGists(sender.stringValue)
            } else {
                searchInGists()
            }
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
                    } else if responseCode == NSModalResponseStop {
                        self.updateLoginStatus()
                    }

                })
                return
            }
            throw ServiceError.IncorrectViewControllerClass
        }
        throw ServiceError.NoViewController
    }
    
    @IBAction func goProClicked(sender: AnyObject) {
        openGoProWindowController(sender)
    }

    func openGoProWindowController(sender: AnyObject) {
        if let windowController = storyboard?.instantiateControllerWithIdentifier("GoProWindowController") as? NSWindowController {
            if let viewController = windowController.contentViewController as? GoProViewController {
                
                windowController.showWindow(sender)
                goProWindow = windowController
                goProView = viewController
                return 
            }
        }
    }

    @IBAction func newGist(sender: FontAwesomeButton) {
        
        /*
         self.filename = filename
         self.size = size
         self.rawUrl = rawUrl
         self.type = type
         self.language = language
         self.isTruncated = isTruncated
         self.content = content
         self.gistId = gistId
 */
        let file = File(value: [
                "filename": "gisttools.js",
                "size": 0,
                "rawUrl": "http://",
                "type": "Javascript",
                "language": "Javascript",
                "isTruncated": false,
                "content": "content",
                "gistId": Gist.temporaryGistId
            ])
        
        let newGist = Gist(value: ["gistId": Gist.temporaryGistId,
            "gistDescription": "Description of gist",
            "htmlUrl": "",
            "createdAt": NSDate(),
            "updatedAt": NSDate(),
            "isGistPublic": true,
            "firstFilename": "gisttool.js",
            "files": [file]
            ])
        
        try! realm.write {
            realm.add(newGist)
        }
        openGistInfo(newGist)
        
        
    }
    @IBAction func authButtonClicked(sender: NSButton) {
        try! openViewControllerWithLoader(self.loader, sender: sender)
    }

    @IBAction func refreshGists(sender: FontAwesomeButton) {
        loadGists()
    }
    
    func handlePurchasedPro(notification: NSNotification) {
        
        dispatch_sync(dispatch_get_main_queue()) {
            Dialog.showInformation("Thanks!", text: "Thank you very much for buying GistTool Pro Edition")
        }
        
        
        
    }
    
}

