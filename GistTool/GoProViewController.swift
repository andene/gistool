//
//  GoProViewController.swift
//  GistTool
//
//  Created by Andreas Kihlberg on 2016-03-25.
//  Copyright © 2016 Oak. All rights reserved.
//

import Cocoa
import StoreKit

class GoProViewController: NSViewController, SKProductsRequestDelegate, SKPaymentTransactionObserver {
    
    @IBOutlet weak var purchaseButton: NSButton!
    @IBOutlet weak var restoreButton: NSButton!
    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var descriptionLabel: NSTextField!
    
    var product: SKProduct?
    
    
    override func viewDidLoad() {
        
        titleLabel.useLatoWithSize(14, bold: true)
        titleLabel.stringValue = "Purchase Gist Tool Pro Edition"
        
        
        if NSUserDefaults.standardUserDefaults().boolForKey("isPro") {
            titleLabel.stringValue = "You are already owner of Pro Edition"
            descriptionLabel.hidden = true
            purchaseButton.hidden = true
            restoreButton.hidden = true
        }
        
        descriptionLabel.useLatoWithSize(13, bold: false)
        
        // Add observer to observe payment
        SKPaymentQueue.defaultQueue().addTransactionObserver(self)
        
        if SKPaymentQueue.canMakePayments() {
        
            let product = NSSet(object: "io.vift.gisttool.pro")
            let productsRequest = SKProductsRequest(productIdentifiers: product as Set<NSObject>)
            productsRequest.delegate = self
            self.purchaseButton.title = "Loading price"
            productsRequest.start()
        } else {
            self.purchaseButton.title = "Upgrade not available"
        }
    }
    
    func productsRequest (request: SKProductsRequest, didReceiveResponse response: SKProductsResponse) {
        if !response.invalidProductIdentifiers!.isEmpty {
            print("invalid:\(response.invalidProductIdentifiers)")
        }
        if let products = response.products {
            
            let product = products[0]
            self.product = product
            
            if let price = product.price {
                
                let priceFormatter = NSNumberFormatter()
                priceFormatter.numberStyle = .CurrencyStyle
                priceFormatter.locale = product.priceLocale
                
                let priceInUsersLocale = priceFormatter.stringFromNumber(price)
                
                self.purchaseButton.title = "Purchase Pro Edition \(priceInUsersLocale!)"
            }
        }
        
    }
    
    func request(request: SKRequest, didFailWithError error: NSError?) {
        print("Error \(error)")
    }
    
    func restore() {
        SKPaymentQueue.defaultQueue().restoreCompletedTransactions()
    }
    
    
    /*
    * Handle the update on the transaction
    */
    func paymentQueue(queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchased:
                completeTransaction(transaction)
                break
            case SKPaymentTransactionStateFailed:
                failedTransaction(transaction)
                break
            case SKPaymentTransactionStateRestored:
                restoreTransaction(transaction)
                break
            case SKPaymentTransactionStateDeferred:
                break
            case SKPaymentTransactionStatePurchasing:
                break
            default:
                break
            }
        }
    }
    private func completeTransaction(transaction: SKPaymentTransaction) {
        print("completeTransaction...")
        deliverPurchaseNotificatioForIdentifier(transaction.payment.productIdentifier)
        SKPaymentQueue.defaultQueue().finishTransaction(transaction)
    }
    
    private func restoreTransaction(transaction: SKPaymentTransaction) {
        guard let productIdentifier = transaction.originalTransaction?.payment.productIdentifier else { return }
        
        print("restoreTransaction... \(productIdentifier)")
        deliverPurchaseNotificatioForIdentifier(productIdentifier)
        SKPaymentQueue.defaultQueue().finishTransaction(transaction)
    }
    
    private func failedTransaction(transaction: SKPaymentTransaction) {
        print("failedTransaction...")
        
        if transaction.error!.code != SKErrorPaymentCancelled {
            Dialog.showError("Error", text: "Transaction Error: \(transaction.error?.localizedDescription)")
        }
        
        SKPaymentQueue.defaultQueue().finishTransaction(transaction)
    }
    
    private func deliverPurchaseNotificatioForIdentifier(identifier: String?) {
        guard let _ = identifier else { return }
        
        let userDefaults = NSUserDefaults.standardUserDefaults()
        userDefaults.setBool(true, forKey: "isPro")
        NSNotificationCenter.defaultCenter().postNotificationName(GistToolPuchasedPro, object: [])
        
        self.view.window?.close()

        
    }
    
    @IBAction func restoreClicked(sender: AnyObject) {
        restore()
    }
    
    @IBAction func purchase(sender: NSButton) {
        
        if SKPaymentQueue.canMakePayments() {
            if let product = self.product {
                let payment = SKPayment.paymentWithProduct(product)
                SKPaymentQueue.defaultQueue().addPayment(payment as! SKPayment)
            }
            
            
        } else {
            Dialog.showError("Error", text: "Seems that you are not able to perfom in app purschases.")
        }
        
        
    }
}
