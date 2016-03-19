//
//  GistInfoTableCell.swift
//  GistTool
//
//  Created by Andreas Kihlberg on 2016-03-18.
//  Copyright © 2016 Oak. All rights reserved.
//

import Cocoa

class GistInfoTableCell: NSTableCellView {

    @IBOutlet var filenameLabel: NSTextField!
    
    override func awakeFromNib() {
        filenameLabel.useLatoWithSize(13.0, bold: true)
        filenameLabel.textColor = ViewController.getLightTextColor()
    }
    
}
