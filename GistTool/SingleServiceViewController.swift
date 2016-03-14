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
        print("Forget existing tokens")
    }
    
    
    @IBAction func beginAuth(sender: NSButton) {
        print("Begin auth process")
        
        authButton?.title = "Authorizing..."
        authButton?.enabled = false
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleRedirect:", name: OAuth2AppDidReceiveCallbackNotification, object: nil)
        
        loader.authorize(view.window) { didFail, error in
            self.didAuthorize(didFail, error: error)
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
        authButton?.title = "Authorize"
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