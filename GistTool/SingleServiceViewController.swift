//
//  SingleServiceViewController.swift
//  GistTool
//
//  Created by Andreas Kihlberg on 2016-03-12.
//  Copyright © 2016 Oak. All rights reserved.
//

import Cocoa
import p2_OAuth2

class SingleServiceViewController: NSViewController {
    
    var loader: GithubLoader!
    

    @IBOutlet weak var authButton: NSButton!
    @IBOutlet weak var label: NSTextField!
    @IBOutlet weak var signInLabel: NSTextField!
    @IBOutlet weak var closeButton: FontAwesomeButton!
    
    @IBOutlet weak var image: NSImageView!
    
    override func viewDidLoad() {
        self.view.wantsLayer = true
        
        signInLabel.useLatoWithSize(CGFloat(13.0))
        closeButton.updateTitle("\u{f00d}", fontSize: 22.0)
        
        let userDefault = NSUserDefaults.standardUserDefaults()
        if let firstTime = userDefault.boolForKey("firstTimeRunning") as? Bool{
            
        }
        
    }
    
    override func viewDidAppear() {

        let image = NSImage(named: "GitHub_Logo")
        image!.size = NSSize(width: 260, height: 100)
        self.image?.image = image

        
        if loader.isAuthorized() {
            signInLabel.stringValue = "Signed in using"
            authButton?.title = "Sign out"
        }
    }
    
    override func viewWillAppear() {
        view.layer?.backgroundColor = NSColor.whiteColor().CGColor
    }
    @IBAction func closeWindow(sender: NSButton) {
        dismissController(sender)
        
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
        loader.oauth2.forgetTokens()
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
        authButton?.title = "Sign in"
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
    
    func authorizeComplete() {
        loader.requestUserdata() { dict, error in
            
            print("\(dict)")
            
        }
    }
    
    
    
}