//
//  Gist.swift
//  GistTool
//
//  Created by Andreas Kihlberg on 2016-03-18.
//  Copyright © 2016 Oak. All rights reserved.
//

import Cocoa

class Gist: NSObject {

    var id: String!
    var gistDescription:String!
    var htmlUrl: String!
    var createdAt: String!
    var updatedAt: String!
    var isPublic: Bool
    var files: [[String: AnyObject]]!
    var firstFilename: String!
    
    init(id: String,
        description: String,
        htmlUrl: String,
        createdAt: String,
        updatedAt: String,
        isPublic: Bool,
        files: [[String:AnyObject]],
        firstFilename: String) {
        
            self.id = id
            self.gistDescription = description
            self.htmlUrl = htmlUrl
            self.createdAt = createdAt
            self.updatedAt = updatedAt
            self.isPublic = isPublic
            self.files = files
            self.firstFilename = firstFilename
            
            
    }
    
}
