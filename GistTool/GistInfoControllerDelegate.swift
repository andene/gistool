//
//  GistInfoControllerDelegate.swift
//  GistTool
//
//  Created by Andreas Kihlberg on 2016-03-30.
//  Copyright © 2016 Oak. All rights reserved.
//

import Cocoa

protocol GistInfoControllerDelegate: class {
    
    func didUpdateGist(gistDictionary: NSDictionary)
    
    func openGoProWindowController(sender: AnyObject)
    
}
