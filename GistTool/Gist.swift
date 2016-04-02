//
//  Gist.swift
//  GistTool
//
//  Created by Andreas Kihlberg on 2016-03-18.
//  Copyright © 2016 Oak. All rights reserved.
//

import RealmSwift

class Gist: Object {

    static var temporaryGistId = "gisttooltemp"
    
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
    
    func deleteGistAndFiles() {
        let realm = try! Realm()
        
        try! realm.write {
            for file in self.files {
                realm.delete(file)
            }
        }
        
        try! realm.write() {
            realm.delete(self)
        }
    }
    
    func toJSONData() -> NSData? {
        
        var files = [String: AnyObject]()
        
        for file in self.files {
            
            if file.isDeleted {
                files[file.filename] = NSNull()
            } else {
                
                if let oldFilename = file.oldFilename {
                    files[oldFilename] = [
                        "filename": file.filename,
                        "content": file.content
                    ]
                } else {
                    files[file.filename] = [
                        "content": file.content
                    ]
                }
                
            }
        }
        
        let gistJSON: [String: AnyObject] = [
            "description": "\(self.gistDescription)",
            "files": files
        ]
        
        do {
            let gistData = try NSJSONSerialization.dataWithJSONObject(gistJSON, options: NSJSONWritingOptions())
            
            print("\(NSString(data: gistData, encoding: NSUTF8StringEncoding))")
            
            return gistData
            //return NSString(data: gistData, encoding: NSUTF8StringEncoding) as? String
        } catch _ {
            return nil
        }
        
    }

}
