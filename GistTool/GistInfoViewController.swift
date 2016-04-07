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
    @IBOutlet weak var addFileButton: FontAwesomeButton!
    
    @IBOutlet weak var secretGistCheckbox: NSButton!
    
    @IBOutlet weak var loadingSpinner: NSProgressIndicator!
    
    weak var delegate: GistInfoControllerDelegate?
    
    var loader: GithubLoader!
    var loadedGist: Gist?
    
    let realm = try! Realm()
    
    override func viewDidLoad() {
        
        // Layer
        view.wantsLayer = true
        
        closeButton.updateTitle("\u{f00d} Close", fontSize: 14.0)
        closeButton.cursor = NSCursor.pointingHandCursor()
        saveButton.updateTitle("\u{f00c} Save", fontSize: 14.0)
        
        

        addFileButton.updateTitle("\u{f067} Add File", fontSize: 14.0)
        setupTableView()
        
        setColors()
        setupSecretCheckbox()
        
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
    
    func setupSecretCheckbox() {
        if loadedGist!.gistId == Gist.temporaryGistId {
            secretGistCheckbox.hidden = false
        } else {
            secretGistCheckbox.hidden = true
        }
        if loadedGist!.isGistPublic {
            secretGistCheckbox.integerValue = 0
        }
    }
    
    func setColors() {
        
        let titleFont = NSFont(name: "Lato", size: 13.0)
        let pstyle = NSMutableParagraphStyle()
        let attributedTitle = NSAttributedString(string: "Secret Gist", attributes: [
            NSForegroundColorAttributeName : ViewController.getLightTextColor(),
            NSParagraphStyleAttributeName : pstyle,
            NSFontAttributeName: titleFont!
            
            ])
        secretGistCheckbox.attributedTitle = attributedTitle
        
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
            
            let titleFont = NSFont(name: "Menlo", size: 13.0)
            
            
            let pstyle = NSMutableParagraphStyle()
            
            let attributedTitle = NSAttributedString(string: file.content, attributes: [
                NSForegroundColorAttributeName : ViewController.getLightTextColor(),
                NSParagraphStyleAttributeName : pstyle,
                NSFontAttributeName: titleFont!
                
                ])
            
            cell.textView.textStorage?.appendAttributedString(attributedTitle)
            cell.textView.font = titleFont!
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.textViewDidEndEditing), name: NSTextDidChangeNotification, object: cell.textView)
            
            
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
        loadingSpinner.startAnimation([])
        let secret = secretGistCheckbox.integerValue
        
        try! self.realm.write() {
            loadedGist!.gistDescription = descriptionText.stringValue
            if secret == 0 {
                loadedGist!.isGistPublic = true
            } else {
                loadedGist!.isGistPublic = false
            }
            
        }
        
        
        var httpMethod = "PATCH"
        
        if loadedGist!.gistId == Gist.temporaryGistId {
            httpMethod = "POST"
        }
        
        loader.updateGist(loadedGist!, method: httpMethod) { data, error in
            //self.spinner.stopAnimation(sender)
            self.delegate?.didUpdateGist(data!)
            self.closeModal(sender as! NSButton)
        }
        
        
    }
    @IBAction func secretGistClicked(sender: NSButton) {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        if !userDefaults.boolForKey("isPro") {
            self.delegate?.openGoProWindowController(sender)
            secretGistCheckbox.integerValue = 0
        } else {
            print("Toggle")
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
    @IBAction func addFile(sender: FontAwesomeButton) {
        
        let file = File(value: [
            "filename": "gisttools.js",
            "size": 0,
            "rawUrl": "http://",
            "type": "Javascript",
            "language": "Javascript",
            "isTruncated": false,
            "content": "content",
            "gistId": loadedGist!.gistId
            ])
        
        try! self.realm.write() {
            loadedGist!.files.append(file)
            
            filesTableView.reloadData()
        }
        
        
        
    }
    @IBAction func closeModal(sender: NSButton) {
        closeSheet(sender)
    }
}
