//
//  AppDelegate.swift
//  GistTool
//
//  Created by Andreas Kihlberg on 2016-03-08.
//  Copyright © 2016 Oak. All rights reserved.
//

import Cocoa
import p2_OAuth2
import RealmSwift

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSUserNotificationCenterDelegate {

    @IBOutlet weak var MainMenu: NSMenu!
    
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        
        
        NSAppleEventManager.sharedAppleEventManager().setEventHandler(
            self,
            andSelector: "handleURLEvent:withReply",
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL))
        
    }
    
    
    func applicationShouldTerminateAfterLastWindowClosed(sender: NSApplication) -> Bool {
        return true;
    }
    
    
       /**
     * Handle incoming URL Request and post notification through the notificationCenter
     */
    func handleURLEvent(event: NSAppleEventDescriptor, withReply reply: NSAppleEventDescriptor) {
        if let urlString = event.paramDescriptorForKeyword(AEKeyword(keyDirectObject))?.stringValue {
            if let url = NSURL(string: urlString) where "viftio" == url.scheme && "oauth" == url.host {
                NSNotificationCenter.defaultCenter().postNotificationName(OAuth2AppDidReceiveCallbackNotification, object: url)
            }
        }
    }
    
    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application

    }

    @IBAction func emptyLocalCache(sender: AnyObject) {
        let realm = try! Realm()
        try! realm.write() {
            realm.deleteAll()
            
            let notification = NSUserNotification()
            notification.title = "Local cache emptied"
            let notificationCenter = NSUserNotificationCenter.defaultUserNotificationCenter()
            notificationCenter.delegate = self
            notificationCenter.deliverNotification(notification)
        }
    }

    
    /**
     * When preferences is clicked, send a notification
     */
    @IBAction func preferencesClicked(sender: AnyObject) {
        NSNotificationCenter.defaultCenter().postNotificationName(OpenSettingsNotification, object: [])
    }
    
    @IBAction func buyProClicked(sender: AnyObject) {
        NSNotificationCenter.defaultCenter().postNotificationName(OpenGoProNotification, object: [])
    }
    
    @IBAction func helpClicked(sender: AnyObject) {
        let url = NSURL(string: "http://vift.io/gisttool")
        NSWorkspace.sharedWorkspace().openURL(url!)
    }
    
    
    func userNotificationCenter(center: NSUserNotificationCenter, shouldPresentNotification notification: NSUserNotification) -> Bool {
        return true
    }
    
}

