//
//  Gist.swift
//  GistTool
//
//  Created by Andreas Kihlberg on 2016-03-18.
//  Copyright © 2016 Oak. All rights reserved.
//

import Cocoa

struct Gist {

    var id: String!
    var description:String!
    var htmlUrl: String!
    var createdAt: String!
    var updatedAt: String!
    var isPublic: Bool
    var files: [String: AnyObject]
    var firstFilename: String!
    
}
