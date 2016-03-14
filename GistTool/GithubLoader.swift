//
//  GithubLoader.swift
//  GistTool
//
//  Created by Andreas Kihlberg on 2016-03-12.
//  Copyright © 2016 Oak. All rights reserved.
//

import Foundation
import p2_OAuth2

class GithubLoader {
    
//    var oauth2: OAuth2CodeGrant { get }
    
    let baseURL = NSURL(string: "https://api.github.com")!
    
    lazy var oauth2: OAuth2CodeGrant = OAuth2CodeGrant(settings: [
        "client_id": "326d23a086018f8da151",
        "client_secret": "daed7970e8b424e2efd69a7a2224b82f114b1ee5",
        "authorize_uri": "https://github.com/login/oauth/authorize",
        "token_uri": "https://github.com/login/oauth/access_token",
        "scope": "user gist",
        "redirect_uris": ["iamkgistool://oauth/callback"],
        "keychain": true,
        "title": "GistTool",
        "secret_in_body": true,
        "verbose": true
    ])
    
    func request(path: String, callback: ((dict: [NSDictionary]?, error: ErrorType?) -> Void)) {
        
        let url = baseURL.URLByAppendingPathComponent(path)
        let request = oauth2.request(forURL: url)
        
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(request) { data, response, error in
        
            //let strData = NSString(data: data!, encoding: NSUTF8StringEncoding)!

            
            if nil != error {
                dispatch_async(dispatch_get_main_queue()) {
                    callback(dict: nil, error: error)
                }
            } else {
                do {
                    let dict = try NSJSONSerialization.JSONObjectWithData(data!, options: []) as? [NSDictionary]
                    dispatch_async(dispatch_get_main_queue()) {
                        callback(dict: dict, error: nil)
                    }
                }
                catch let error {
                    print("Error \(error)")
                    dispatch_async(dispatch_get_main_queue()) {
                        callback(dict: nil, error: error)
                    }
                }
            }
            
        }
        task.resume()
        
    }
    
    func requestUserdata(callback: ((dict: [NSDictionary]?, error: ErrorType?) -> Void)) {
        request("user", callback: callback)
    }
    
    func requestGists(callback: ((dict: [NSDictionary]?, error: ErrorType?) -> Void )) {
        request("gists", callback: callback)
    }
    
    func isAuthorized() -> Bool {
        return oauth2.hasUnexpiredAccessToken()
    }
    
    func handleRedirectUrl(url: NSURL) {
        oauth2.handleRedirectURL(url)
    }
    
    func authorize(window: NSWindow?, callback: (wasFailure: Bool, error: ErrorType?) -> Void) {
        
        oauth2.authConfig.authorizeEmbedded = true
        oauth2.authConfig.authorizeContext = window
        oauth2.afterAuthorizeOrFailure = callback
        oauth2.authorize()
        
    }
    
    
    
}