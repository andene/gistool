//
//  SingleServiceViewController.swift
//  GistTool
//
//  Created by Andreas Kihlberg on 2016-03-12.
//  Copyright © 2016 Oak. All rights reserved.
//

import Cocoa
import p2_OAuth2
import RealmSwift

class SingleServiceViewController: NSViewController {
    
    var loader: GithubLoader!
    var isSignedIn = false
    var user: NSDictionary!
    
    @IBOutlet weak var authButton: NSButton!
    @IBOutlet weak var label: NSTextField!
    @IBOutlet weak var signInLabel: NSTextField!
    @IBOutlet weak var closeButton: FontAwesomeButton!
    @IBOutlet weak var upgradeButton: NSButton!
    
    @IBOutlet weak var gistToolVersion: NSTextField!
    @IBOutlet weak var gisttoolVersionLabel: NSTextField!
    
    @IBOutlet weak var descriptionLabel: NSTextField!
    @IBOutlet weak var darkthemeLabel: NSTextField!
    @IBOutlet weak var darkthemeCheckbox: NSButton!
    
    override func viewDidLoad() {
        self.view.wantsLayer = true
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.handlePurchasedPro), name: GistToolPuchasedPro, object: nil)
        
        
        setupElements()
        handlePro()
        
        let userDefault = NSUserDefaults.standardUserDefaults()
        if userDefault.boolForKey("firstTimeRunning") {
            
        }
        
        
        if userDefault.boolForKey("darkTheme") {
            darkthemeCheckbox.integerValue = 1
        }
        
        
        
    }
    
    func handlePro() {
        if NSUserDefaults.standardUserDefaults().boolForKey("isPro") {
            gisttoolVersionLabel.stringValue = "Pro edition"
            upgradeButton.hidden = true
        }
    }
    
    
    // Called when a notification of purchase is made
    func handlePurchasedPro() {
        handlePro()
    }
    
    
    func setupElements() {
        let backgroundColor = ViewController.getBackgroundColor()
        view.layer?.backgroundColor = backgroundColor.CGColor
        
        signInLabel.useLatoWithSize(CGFloat(14.0),  bold: false)
        closeButton.updateTitle("\u{f00d} Close", fontSize: 16.0)
        
        gisttoolVersionLabel.useLatoWithSize(14.0, bold: false)
        gistToolVersion.useLatoWithSize(14.0, bold: false)
        
        darkthemeLabel.useLatoWithSize(14.0, bold: false)
        darkthemeCheckbox.currentEditor()?.textColor = ViewController.getLightTextColor()
        
        descriptionLabel.useLatoWithSize(14, bold: false)
        
        setupWelcomeText()
        setupCheckbox()
    }
    
    func setupCheckbox() {
        
        let titleFont = NSFont(name: "Lato", size: 14.0)
        
        let pstyle = NSMutableParagraphStyle()
        
        let attributedTitle = NSAttributedString(string: "Enable Dark theme", attributes: [
            NSForegroundColorAttributeName : ViewController.getMediumTextColor(),
            NSParagraphStyleAttributeName : pstyle,
            NSFontAttributeName: titleFont!
            
            ])
        
        self.darkthemeCheckbox.attributedTitle = attributedTitle
    }
    
    func setupWelcomeText() {
        if !isSignedIn {
            descriptionLabel.stringValue = "To get started with GistTool you need to log in to your Github account. Click sign in below to get started!"
        } else {
            
            if let username = user["login"] {
                self.descriptionLabel.stringValue = "Signed in as: \(username)"
            }
        }
        
    }
    
    override func viewDidAppear() {
        
        if loader.isAuthorized() {
            
            signInLabel.stringValue = "Signed in"
            loader.requestUserdata() { dict, error in
                
                if let userDict = dict {
                    self.user = userDict
                    self.isSignedIn = true
                    self.setupWelcomeText()
                }
            }
            authButton?.title = "Sign out"
        }
    }
    
    override func viewWillAppear() {
        setupElements()
    }
    
    func deleteAllObjectsInDatabase() {
        let realm = try! Realm()
        try! realm.write() {
            realm.deleteAll()
        }
    }
    
    // Close window with button
    @IBAction func closeWindow(sender: NSButton) {
        view.window!.sheetParent?.endSheet(self.view.window!, returnCode: NSModalResponseCancel)
        view.window?.close()
    }
    
    /** Forwards to `displayError(NSError)`. */
    func showError(error: ErrorType) {
        if let error = error as? OAuth2Error {
            let err = NSError(domain: "OAuth2ErrorDomain", code: 0, userInfo: [NSLocalizedDescriptionKey: error.description])
            displayError(err)
        }
        else {
            displayError(error as NSError)
        }
    }
    
    /** Alert or log the given NSError. */
    func displayError(error: NSError) {
        if let window = self.view.window {
            NSAlert(error: error).beginSheetModalForWindow(window, completionHandler: nil)
            label?.stringValue = error.localizedDescription
        }
        else {
            NSLog("Error authorizing: \(error.description)")
        }
    }
    
    
    @IBAction func forgetTokens(sender: NSButton) {
        deleteAllObjectsInDatabase()
        loader.oauth2.forgetTokens()
        
        view.window!.sheetParent?.endSheet(self.view.window!, returnCode: NSModalResponseStop)
        view.window?.close()
        
    }
    
    @IBAction func toggleDarkTheme(sender: AnyObject) {
        
        let userDefaults = NSUserDefaults.standardUserDefaults()
        
        if !userDefaults.boolForKey("isPro") {
            darkthemeCheckbox.integerValue = 0
            NSNotificationCenter.defaultCenter().postNotificationName(OpenGoProNotification, object: [])
        
        } else {
            if darkthemeCheckbox.integerValue == 1 {
                userDefaults.setBool(true, forKey: "darkTheme")
            } else {
                userDefaults.setBool(false, forKey: "darkTheme")
            }
            setupElements()
            NSNotificationCenter.defaultCenter().postNotificationName(DarkThemeChangedNotification, object: [])
            
        }
        
        
    }
    
    @IBAction func beginAuth(sender: NSButton) {

        if loader.isAuthorized() {
            forgetTokens(sender)
        } else {
            authButton?.title = "Authorizing..."
            authButton?.enabled = false
            
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleRedirect:", name: OAuth2AppDidReceiveCallbackNotification, object: nil)
            
            loader.authorize(view.window) { didFail, error in
                self.didAuthorize(didFail, error: error)
            }
        }
        
        
    }
    
    func didAuthorize(didFail: Bool, error: ErrorType?) {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: OAuth2AppDidReceiveCallbackNotification, object: nil)
        
        if didFail {
            if let error = error {
                showError(error)
            }
        } else {
            self.authorizeComplete()
        }
        authButton?.title = "Sign in with Github"
        authButton?.enabled = true
        
    }
    
    
    func handleRedirect(notification: NSNotification) {
        if let url = notification.object as? NSURL {
            loader.handleRedirectUrl(url)
        }
        else {
            showError(NSError(domain: NSCocoaErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid notification: did not contain a URL"]))
        }
    }
    
    @IBAction func upgradeToProClicked(sender: AnyObject) {
        NSNotificationCenter.defaultCenter().postNotificationName(OpenGoProNotification, object: [])
    }
    func authorizeComplete() {
        
        view.window!.sheetParent?.endSheet(self.view.window!, returnCode: NSModalResponseOK)
        view.window?.close()
        
        loader.requestUserdata() { dict, error in
            
            print("\(dict)")
            
        }
    }
    
    
    
}