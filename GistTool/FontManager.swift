//
//  FontManager.swift
//  GistTool
//
//  Created by Andreas Kihlberg on 2016-03-27.
//  Copyright © 2016 Oak. All rights reserved.
//

import Cocoa

class FontManager{
    func loadFont(name: String, fontExtension: String) {
    
        let bundle = NSBundle(forClass: ViewController.self)
        var fontURL = NSURL()
        
        fontURL = bundle.URLForResource(name, withExtension: fontExtension)!
        
        let data = NSData(contentsOfURL: fontURL)
        let provider = CGDataProviderCreateWithCFData(data)
        let font = CGFontCreateWithDataProvider(provider)
        var error: Unmanaged<CFError>?
        if !CTFontManagerRegisterGraphicsFont(font!, &error) {
            let errorDescription: CFStringRef = CFErrorCopyDescription(error!.takeUnretainedValue())
            let nsError = error!.takeUnretainedValue() as AnyObject as! NSError
            NSException(name: NSInternalInconsistencyException, reason: errorDescription as String, userInfo: [NSUnderlyingErrorKey: nsError]).raise()
        }
    
    
    
    }
}
