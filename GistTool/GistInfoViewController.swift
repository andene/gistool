//
//  GistInfoViewController.swift
//  GistTool
//
//  Created by Andreas Kihlberg on 2016-03-15.
//  Copyright © 2016 Oak. All rights reserved.
//

import Cocoa
import Quartz
import RealmSwift

class GistInfoViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    
    @IBOutlet weak var closeButton: FontAwesomeButton!
    @IBOutlet weak var saveButton: FontAwesomeButton!
    @IBOutlet weak var descriptionText: EditableTextField!
    @IBOutlet weak var dateLabel: NSTextField!
    @IBOutlet weak var filesTableView: NSTableView!
    
    
    weak var delegate: GistInfoControllerDelegate?
    
    var loader: GithubLoader!
    var loadedGist: Gist?
    
    let realm = try! Realm()
    
    override func viewDidLoad() {
        
        // Layer
        view.wantsLayer = true
        
        closeButton.updateTitle("\u{f00d}", fontSize: 22.0)
        saveButton.updateTitle("\u{f00c}", fontSize: 22.0)
        
        setupTableView()
        
        
        if let gist = self.loadedGist {
            
            descriptionText.useLatoWithSize(14.0, bold: false)
            descriptionText.textColor = ViewController.getLightTextColor()
            descriptionText.stringValue = gist.gistDescription
            descriptionText.backgroundColor = ViewController.getBackgroundColor()
            descriptionText.focusRingType = NSFocusRingType.None

            
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateStyle = NSDateFormatterStyle.LongStyle
            dateFormatter.timeStyle = .MediumStyle
            
            let created = dateFormatter.stringFromDate(gist.createdAt!)
            let updated = dateFormatter.stringFromDate(gist.updatedAt!)
            
            dateLabel.useLatoWithSize(10.0, bold: false)
            dateLabel.textColor = ViewController.getMediumTextColor()
            dateLabel.stringValue = "Created at \(created), Updated at \(updated)"
        }
        
    }
    
    override func keyDown(theEvent: NSEvent) {
        interpretKeyEvents([theEvent])
    }
    
    override func cancelOperation(sender: AnyObject?) {
        closeSheet([])
    }
    
    // Setup stuff on table view
    func setupTableView() {
        filesTableView.setDataSource(self)
        filesTableView.setDelegate(self)
        filesTableView.rowHeight = 200.0
        filesTableView.target = self
        filesTableView.backgroundColor = ViewController.getBackgroundColor()
        
    }
    
    
    func tableView(tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        let tableRow = GistInfoTableRow()
        return tableRow
    }
    
    func getFilesNotDeleted() -> Results<File> {
        return loadedGist!.files.filter("isDeleted == 0")
    }
    
    func getDeletedFiles() -> Results<File> {
        return loadedGist!.files.filter("isDeleted == 1")
    }
    
    
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        let file = getFilesNotDeleted()[row]
        
        guard let filename = file["filename"] as? String
            
            else {
                return nil
        }
        
        
        if let cell = tableView.makeViewWithIdentifier("mainCell", owner: nil) as? GistInfoTableCell {
            cell.filenameLabel.stringValue = filename
            cell.filenameLabel.editable = true
            
            cell.viewController = self
            cell.file = file
            
            let titleFont = NSFont(name: "Menlo", size: 12.0)
            
            
            let pstyle = NSMutableParagraphStyle()
            
            let attributedTitle = NSAttributedString(string: file.content, attributes: [
                NSForegroundColorAttributeName : ViewController.getMediumTextColor(),
                NSParagraphStyleAttributeName : pstyle,
                NSFontAttributeName: titleFont!
                
                ])
            
            cell.textView.textStorage?.appendAttributedString(attributedTitle)
            
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.textViewDidEndEditing), name: NSTextDidEndEditingNotification, object: cell.textView)
            
            
            return cell
        }
        return nil
        
    }
    
    func textViewDidEndEditing(notification: NSNotification) {
        
        if let textView = notification.object as? NSTextView {
            let rowChanged = filesTableView.rowForView(textView)
            let file = getFilesNotDeleted()[rowChanged]
            try! self.realm.write() {
                if let textStorage = textView.textStorage {
                    file.content = textStorage.string
                }
                
            }
            
        }
    }
    
    
    
    @IBAction func save(sender: AnyObject) {

        try! self.realm.write() {
            loadedGist!.gistDescription = descriptionText.stringValue
        }
        
        
        var httpMethod = "PATCH"
        
        if loadedGist!.gistId == Gist.temporaryGistId {
            httpMethod = "POST"
        }
        
        loader.updateGist(loadedGist!, method: httpMethod) { data, error in
            self.delegate?.didUpdateGist(data!)
            self.closeModal(sender as! NSButton)
        }
        
        
    }
    
    @IBAction func endEditingText(sender: EditableTextField) {
        let newFilename = sender.stringValue as String
        let rowChanged = filesTableView.rowForView(sender)
        
        let file = getFilesNotDeleted()[rowChanged]
        try! self.realm.write() {
            if file.filename != newFilename {
                file.oldFilename = file.filename
            }
            
            file.filename = newFilename
        }
    }
    
    
    
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        if let _ = loadedGist {
            return getFilesNotDeleted().count
        } else {
            return 0
        }
        
    }
    
    func deleteFile(file: File) {
        try! self.realm.write() {
            file.isDeleted = true
        }
        filesTableView.reloadData()
    }
    
    override func viewWillAppear() {
        view.layer?.backgroundColor = ViewController.getBackgroundColor().CGColor
    }
    
    // If user has deleted files and closes the modal, undelete the files
    func unDeleteFiles() {
        let deletedFiles = getDeletedFiles()
        for file in deletedFiles {
            try! self.realm.write() {
                file.isDeleted = false
            }
        }
    }
    
    
    /**
     * When creating a new gist a temporary record is saved in database
     */
    func removeTemporaryGistFromRealm() {
        if loadedGist!.gistId == "gisttooltemp" {
            
            try! realm.write {
                for file in loadedGist!.files {
                    realm.delete(file)
                }
            }
            
            try! self.realm.write() {
                realm.delete(loadedGist!)
            }
        }
    }
    
    func closeSheet(sender: AnyObject) {
        unDeleteFiles()
        removeTemporaryGistFromRealm()
        dismissController(sender)

    }
    @IBAction func closeModal(sender: NSButton) {
        closeSheet(sender)
    }
}
