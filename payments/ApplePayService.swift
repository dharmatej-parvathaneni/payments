//
//  ApplePayService.swift
//  payments
//
//  Created by Dharmatej Parvathaneni on 4/24/20.
//  Copyright © 2020 https://github.com/dharmatej-parvathaneni . All rights reserved.
//

import PassKit
import Firebase

protocol ApplePayServiceType: class {
    func isDeviceCompatible() -> Bool
    func showPaymentSheet(depositAmount: Float)
    func paymentButton() -> PKPaymentButton
    func subscribeToTopic(topic: String) -> Void
    func unSubscribeFromTopic(timeout: Bool?) -> Void
}

class ApplePayService: NSObject, ApplePayServiceType {
    
    // MARK: Public vars/constants
    public static let appSvc = ApplePayService()
    
    // MARK: Private vars
    private let supportedPaymentNetworks: [PKPaymentNetwork] = [.visa, .masterCard, .amex]
    
    private var topicName: String = ""
    
    // MARK: Public Methods
    func isDeviceCompatible() -> Bool {
        PKPaymentAuthorizationController.canMakePayments()
    }
    
    func paymentButton() -> PKPaymentButton {
        var buttonStyle = PKPaymentButtonStyle.black
        if #available(iOS 12.0, *) {
            if UIScreen.main.traitCollection.userInterfaceStyle == UIUserInterfaceStyle.dark {
                buttonStyle = .whiteOutline
            }
        }
        
        var buttonType = PKPaymentButtonType.setUp
        if self.isDeviceCompatible() {
            buttonType = .plain
        }
        
        return PKPaymentButton(paymentButtonType: buttonType, paymentButtonStyle: buttonStyle)
    }
    
    func showPaymentSheet(depositAmount: Float) {
        if self.isDeviceCompatible() {
            let request = PKPaymentRequest()
            request.currencyCode = "USD"
            request.countryCode = "US"
            request.merchantIdentifier = Configuration.Merchant.identifier
            request.merchantCapabilities = .capability3DS
            request.supportedNetworks = supportedPaymentNetworks
            request.paymentSummaryItems = [
                PKPaymentSummaryItem.init(label: "Deposit Amount", amount: NSDecimalNumber(value: depositAmount)),
                PKPaymentSummaryItem.init(label: "Transaction Fees", amount: NSDecimalNumber(value: Float("5")!)),
                PKPaymentSummaryItem.init(label: "TwinSpires", amount: NSDecimalNumber(value: Float(depositAmount + Float("5")!)))
            ]
            request.requiredBillingContactFields = [ .postalAddress ]
            
            let paymentRequest = PKPaymentAuthorizationController(paymentRequest: request)
            paymentRequest.delegate = self
            paymentRequest.present(completion: nil)
        } else {
            let passLib = PKPassLibrary()
            passLib.openPaymentSetup()
        }
    }
    
    func subscribeToTopic(topic: String) -> Void {
        self.topicName = topic
        Messaging.messaging().subscribe(toTopic: self.topicName) { error in
          print("Subscribed to ApplePayDeposit topic")
        }
    }
    
    func unSubscribeFromTopic(timeout: Bool? = false) -> Void {
        if (self.topicName != "") {
            Messaging.messaging().unsubscribe(fromTopic: self.topicName) { error in
                if timeout! {
                    print("UN-Subscribed from topic due to timeout")
                } else {
                    print("UN-Subscribed from ApplePayDeposit topic")
                }
                self.topicName = ""
            }
        }
    }
}

extension ApplePayService: PKPaymentAuthorizationControllerDelegate {
    func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
        controller.dismiss(completion: nil)
    }
    
    func paymentAuthorizationController(_ controller: PKPaymentAuthorizationController, didAuthorizePayment payment: PKPayment, handler completion: @escaping (PKPaymentAuthorizationResult) -> Void) {
       
        var tokenData: ApplePayTokenData?
        do {
            tokenData = try JSONDecoder().decode(ApplePayTokenData.self, from: payment.token.paymentData)
        } catch {
            print("Error capturing Data: \(error.localizedDescription).")
        }
        
        print("\(#function) Triggerd,  Version: \(String(describing: tokenData!.version))")
        print("Data: \(String(describing: tokenData!.data))")
        print("Signature: \(String(describing: tokenData!.signature))")
        print("Header: \(String(describing: tokenData!.header))")
        print("paymentDisplayName: \(String(describing: payment.token.paymentMethod.displayName!))")
        print("Address1: \(String(describing: payment.billingContact!.postalAddress!.street))")
        print("City: \(String(describing: payment.billingContact!.postalAddress!.city))")
        print("State: \(String(describing: payment.billingContact!.postalAddress!.state))")
        print("ZipCode: \(String(describing: payment.billingContact!.postalAddress!.postalCode))")
        print("transactionIdentifier: \(String(describing: payment.token.transactionIdentifier))")
        
        // Retrieve the TransactionID and Subscribe to Topic - self.topicName
        var status: PKPaymentAuthorizationStatus = .failure
        if !payment.token.transactionIdentifier.contains("Simulated") {
            self.subscribeToTopic(topic: payment.token.transactionIdentifier)
            DispatchQueue.main.asyncAfter(deadline: .now() + 30.0) {
                self.unSubscribeFromTopic(timeout: true)
            }
            status = .success
        }
        
        completion(PKPaymentAuthorizationResult.init(status: status, errors: nil))
    }
}


struct ApplePayTokenData: Decodable {
    let version: String
    let data: String
    let signature: String
    let header: ApplePayTokenDataHeader
}

struct ApplePayTokenDataHeader: Decodable {
    let ephemeralPublicKey: String
    let publicKeyHash: String
    let transactionId: String
}
