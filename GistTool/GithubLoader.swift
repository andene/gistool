//
//  GithubLoader.swift
//  GistTool
//
//  Created by Andreas Kihlberg on 2016-03-12.
//  Copyright © 2016 Oak. All rights reserved.
//

import Foundation
import p2_OAuth2
import RealmSwift

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
    
    
    /**
     *  Request a list of users gists
     *  @param path The endpoint path in Githubs API
     *  @param callback A tuple returning gists and error
     */
    
    func request(path: String, callback: ((gists: [Gist]?, error: ErrorType?) -> Void)) {
    
        let url = baseURL.URLByAppendingPathComponent(path)
        let request = oauth2.request(forURL: url)
        request.cachePolicy = NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData
        
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        
        if !self.isAuthorized() {
            callback(gists: nil, error: NSError(domain: "iamk", code: 0, userInfo: ["error": "User not authorized"]))
        } else {
        
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
                            
                            let gists = [Gist]()
                            for gist in jsonGists! {
                                
                                guard let id = gist["id"] as? String,
                                    let updatedAt = gist["updated_at"] as? String
                                    else {
                                        callback(gists: nil, error: NSError(domain: "iamk", code: 0, userInfo: ["error": "No gists found"]))
                                        break
                                }
                                
                                // Check if Gist exist in database
                                let realm = try! Realm()
                                
                                if let gistRecord = realm.objects(Gist).filter("gistId == %@", id).first {
                                    
                                    let updatedDate = self.getDateFromString(updatedAt)
                                    
                                    let dateCompare = updatedDate.compare(gistRecord.updatedAt!)
                                    if dateCompare == NSComparisonResult.OrderedDescending {
                                        print("Gist is updated, replace: \(gistRecord.gistDescription)")
                                        
                                        // Add the gist again
                                        if let newGist = self.createGistFromJSON(gist, callback: callback) {
                                            
                                            // If we could update the gist, delete all files before adding them
                                            self.deleteGistFiles(gistRecord)
                                            
                                            
                                            self.createGistItem(newGist)
                                            let url = "gists/" + id
                                            
                                            self.requestGistFiles(url) { gistFiles, error in
                                                if let foundGistFiles = gistFiles {
                                                    for file in foundGistFiles {
                                                        try! realm.write() {
                                                            gistRecord.files.append(file)
                                                        }
                                                    }
                                                }
                                                
                                            }
                                        }
                                    }
                                    
                                    
                                } else  {
                                    if let newGist = self.createGistFromJSON(gist, callback: callback) {
                                        self.createGistItem(newGist)
                                        let url = "gists/" + id
                                        
                                        if let gistRecord = realm.objects(Gist).filter("gistId == %@", id).first {
                                            self.requestGistFiles(url) { gistFiles, error in
                                                if nil != error {
                                                    print("Error \(error)")
                                                } else {
                                                    for file in gistFiles! {
                                                        try! realm.write() {
                                                            gistRecord.files.append(file)
                                                        }
                                                    }
                                                }
                                                
                                            }
                                        }
                                    }
                                }
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
        
    }
    
    func deleteGistFiles(gist:Gist) {
        let realm = try! Realm()
        
        try! realm.write {
            for file in gist.files {
                realm.delete(file)
            }
        }
    }
    
    func requestGistFiles(path: String, callback: ((gistFiles: [File]?, error: ErrorType?) -> Void)) {
        
        let url = baseURL.URLByAppendingPathComponent(path)
        let request = oauth2.request(forURL: url)
        request.cachePolicy = NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData
        print("Request \(url)")
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(request) { data, response, error in
            if nil != error {
                dispatch_async(dispatch_get_main_queue()) {
                    callback(gistFiles: nil, error: error)
                }
            } else {
                do {
                    let jsonGists = try NSJSONSerialization.JSONObjectWithData(data!, options: []) as? NSDictionary
                    dispatch_async(dispatch_get_main_queue()) {
                        
                        var gistFiles = [File]()
                        if let gist = jsonGists {
                        
                            if let gistId = gist["id"] as? String {
                            
                                if let files = gist["files"] as? NSDictionary {
                                    
                                    let gistFileArray = self.handleGistFiles(files)

                                
                                    for file in gistFileArray {
                                        guard let filename = file["filename"] as? String,
                                            let size = file["size"] as? Int,
                                            let rawUrl = file["raw_url"] as? String,
                                            let content = file["content"] as? String,
                                            let type = file["type"] as? String
                                            else {
                                                print("Files for gist \(gistFileArray)")
                                                callback(gistFiles: nil, error: NSError(domain: "iamk", code: 0, userInfo: ["error": "No gists found"]))
                                                break
                                        }
                                    
                                        var isTruncated = false
                                        if let _ = file["truncated"] as? Bool {
                                            isTruncated = true
                                        }
                                    
                                        var language = ""
                                        if let fileLanguage = file["language"] as? String {
                                            language = fileLanguage
                                        }
                                        
                                        let gistFile = File(filename: filename,
                                            size: size,
                                            rawUrl: rawUrl,
                                            type: type,
                                            language: language,
                                            isTruncated: isTruncated,
                                            content: content,
                                            gistId: gistId)
                                    
                                        gistFiles.append(gistFile)
                                    }
                            } else {
                                callback(gistFiles: nil, error: NSError(domain: "iamk", code: 0, userInfo: ["error": "No gists found"]))
                            }
                                
                            }
                        }
                        
                        callback(gistFiles: gistFiles, error: nil)
                    }
                }
                catch let error {
                    print("Error \(error)")
                    dispatch_async(dispatch_get_main_queue()) {
                        callback(gistFiles: nil, error: error)
                    }
                }
            }
            
        }
        task.resume()
        
    }

    
    func createGistFromJSON(gist: NSDictionary, callback: ((gists: [Gist]?, error: ErrorType?) -> Void)) -> Gist? {
        
        guard let id = gist["id"] as? String,
            let htmlURL = gist["html_url"] as? String,
            let description = gist["description"] as? String,
            let createdAt = gist["created_at"] as? String,
            let updatedAt = gist["updated_at"] as? String,
            let isGistPublic = gist["public"] as? Bool,
            let files = gist["files"] as? NSDictionary,
            
            let firstFile = files.allValues.first as? NSDictionary,
            let fileName = firstFile.objectForKey("filename") as? String
            else {
                callback(gists: nil, error: NSError(domain: "iamk", code: 0, userInfo: ["error": "No gists found"]))
                return nil
        }
        
        let createdDated = self.getDateFromString(createdAt)
        let updatedDate = self.getDateFromString(updatedAt)
        
        let newGist = Gist(gistId: id,
            description: description,
            htmlUrl: htmlURL,
            createdAt: createdDated,
            updatedAt: updatedDate,
            isGistPublic: isGistPublic,
            firstFilename: fileName)
        
        return newGist

    }
    
    
    func getDateFromString(date: String) -> NSDate {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        let parsedDate = dateFormatter.dateFromString(date) as NSDate!
        return parsedDate
    }
    
    
    func createGistItem(gist: Gist) {
        
        let realm = try! Realm()
        try! realm.write {
            realm.add(gist, update: true)
        }

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
    
    func updateGist(gist: Gist, method: String, callback: ((dict: NSDictionary?, error: ErrorType?) -> Void)) {
        
        var url = baseURL.URLByAppendingPathComponent("gists")
        
        if method == "PATCH" {
            url = baseURL.URLByAppendingPathComponent("gists").URLByAppendingPathComponent(gist.gistId)
        }
        
        let request = oauth2.request(forURL: url)
        request.cachePolicy = NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData
        
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Content-Type")
        
        print("URL \(url)")
        
        request.HTTPMethod = method
        
        if let jsonFromGist = gist.toJSONData() {
            request.HTTPBody = jsonFromGist
        
            let jsonString = NSString(data: jsonFromGist, encoding: NSUTF8StringEncoding)
            
            if let json = jsonString {
                request.setValue("\(json.length)", forHTTPHeaderField: "Content-Length")
            }
            
        }
        
        NSURLSession.sharedSession().dataTaskWithRequest(request) { data, response, error in
            
            if let _ = response as? NSHTTPURLResponse {
                
            }
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
    
    func deleteGist(gist: Gist, callback: ((statusCode: Int?, error: ErrorType?) -> Void)) {
        
        let url = baseURL.URLByAppendingPathComponent("gists").URLByAppendingPathComponent(gist.gistId)
        let request = oauth2.request(forURL: url)
        request.cachePolicy = NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData
        
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        
        print("URL \(url)")
        
        request.HTTPMethod = "DELETE"
        
        NSURLSession.sharedSession().dataTaskWithRequest(request) { data, response, error in
            
            if nil != error {
                dispatch_async(dispatch_get_main_queue()) {
                    callback(statusCode: nil, error: error)
                }
            } else {
                do {
                    
                    if let httpResponse = response as? NSHTTPURLResponse {
                        dispatch_async(dispatch_get_main_queue()) {
                            callback(statusCode: httpResponse.statusCode, error: nil)
                        }
                    }
                    
                }
                catch let error {
                    dispatch_async(dispatch_get_main_queue()) {
                        callback(statusCode: nil, error: error)
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
    
    func requestSingleGist(id: String, callback: ((gists: NSDictionary?, error: ErrorType?)-> Void )) {
        
        let url = "gists/" + id
        requestSingle(url, callback: callback)
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