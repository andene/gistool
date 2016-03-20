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
    
    func request(path: String, callback: ((gists: [Gist]?, error: ErrorType?) -> Void)) {
        
        let url = baseURL.URLByAppendingPathComponent(path)
        let request = oauth2.request(forURL: url)
        request.cachePolicy = NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData
        
        print("Fetching URL \(url)")
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        
        //print("Request sent \(request)")
        
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(request) { data, response, error in
            if nil != error {
                dispatch_async(dispatch_get_main_queue()) {
                    callback(gists: nil, error: error)
                }
            } else {
                do {
                    let jsonGists = try NSJSONSerialization.JSONObjectWithData(data!, options: []) as? [NSDictionary]
                    dispatch_async(dispatch_get_main_queue()) {
                        
                        var gists = [Gist]()
                        for gist in jsonGists! {
                            
                            guard let id = gist["id"] as? String,
                                let htmlURL = gist["html_url"] as? String,
                                let description = gist["description"] as? String,
                                let createdAt = gist["created_at"] as? String,
                                let updatedAt = gist["updated_at"] as? String,
                                let isPublic = gist["public"] as? Bool,
                                let files = gist["files"] as? NSDictionary,
                                
                                let firstFile = files.allValues.first as? NSDictionary,
                                let fileName = firstFile.objectForKey("filename") as? String
                                else {
                                    callback(gists: nil, error: NSError(domain: "iamk", code: 0, userInfo: ["error": "No gists found"]))
                                    break
                            }
                            
                            
                            let gistFiles = self.handleGistFiles(files)
                            
                            let newGist = Gist(id: id,
                                description: description,
                                htmlUrl: htmlURL,
                                createdAt: createdAt,
                                updatedAt: updatedAt,
                                isPublic: isPublic,
                                files: gistFiles,
                                firstFilename: fileName)

                            
                            gists.append(newGist)
                        }
                        
                        callback(gists: gists, error: nil)
                    }
                }
                catch let error {
                    print("Error \(error)")
                    dispatch_async(dispatch_get_main_queue()) {
                        callback(gists: nil, error: error)
                    }
                }
            }
            
        }
        task.resume()
        
    }
    
    func handleGistFiles(files: NSDictionary) -> [[String: AnyObject]] {
        var gistFiles = [[String: AnyObject]]()
        
        for (_, value) in files {
            let fileData = value as! NSDictionary
                gistFiles.append(fileData as! [String : AnyObject])
        }
        
        return gistFiles

    }

    
    func requestSingle(path: String, callback: ((dict: NSDictionary?, error: ErrorType?) -> Void)) {
        
        let url = baseURL.URLByAppendingPathComponent(path)
        let request = oauth2.request(forURL: url)
        print("Fetching URL \(url)")
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        
        NSURLSession.sharedSession().dataTaskWithRequest(request) { data, response, error in
            if nil != error {
                dispatch_async(dispatch_get_main_queue()) {
                    callback(dict: nil, error: error)
                }
            } else {
                do {
                    let dict = try NSJSONSerialization.JSONObjectWithData(data!, options: []) as? NSDictionary
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
        }.resume()
    }
    
    
    func requestUserdata(callback: ((dict: NSDictionary?, error: ErrorType?) -> Void)) {
        requestSingle("user", callback: callback)
    }
    
    func requestGists(callback: ((gists: [Gist]?, error: ErrorType?) -> Void )) {
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