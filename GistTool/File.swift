//
//  File.swift
//  GistTool
//
//  Created by Andreas Kihlberg on 2016-03-20.
//  Copyright © 2016 Oak. All rights reserved.
//

import RealmSwift

class File: Object {
   
    dynamic var filename: String = ""
    dynamic var size: Int = 0
    dynamic var rawUrl: String = ""
    dynamic var type: String = ""
    dynamic var language: String = ""
    dynamic var isTruncated: Bool = false
    dynamic var content: String = ""
    dynamic var gistId: String = ""
    
    convenience init(filename: String, size: Int, rawUrl: String, type: String, language: String, isTruncated: Bool, content: String, gistId: String) {
        self.init()
        
        self.filename = filename
        self.size = size
        self.rawUrl = rawUrl
        self.type = type
        self.language = language
        self.isTruncated = isTruncated
        self.content = content
        self.gistId = gistId
        
    }

}
