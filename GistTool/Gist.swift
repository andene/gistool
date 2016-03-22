//
//  Gist.swift
//  GistTool
//
//  Created by Andreas Kihlberg on 2016-03-18.
//  Copyright © 2016 Oak. All rights reserved.
//

import RealmSwift

class Gist: Object {

    dynamic var gistId: String!
    dynamic var gistDescription:String!
    dynamic var htmlUrl: String!
    dynamic var createdAt: NSDate? = nil
    dynamic var updatedAt: NSDate? = nil
    dynamic var isGistPublic: Bool = false
    dynamic var firstFilename: String!
    let files = List<File>()
    
    override static func primaryKey() -> String? {
        return "gistId"
    }
    
    convenience init(gistId: String,
        description: String,
        htmlUrl: String,
        createdAt: NSDate?,
        updatedAt: NSDate?,
        isGistPublic: Bool,
        firstFilename: String) {
            
            self.init()
            self.gistId = gistId
            self.gistDescription = description
            self.htmlUrl = htmlUrl
            self.createdAt = createdAt
            self.updatedAt = updatedAt
            self.isGistPublic = isGistPublic
            //self.files = files
            self.firstFilename = firstFilename

            
    }
    

}
