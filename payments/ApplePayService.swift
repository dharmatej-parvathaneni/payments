//
//  ApplePayService.swift
//  payments
//
//  Created by Dharmatej Parvathaneni on 4/24/20.
//  Copyright © 2020 twinspires. All rights reserved.
//

import PassKit

protocol ApplePayServiceType: class {
    func isDeviceCompatible() -> Bool
    func isDeviceSetUp() -> Bool
    func showPaymentSheet(depositAmount: Float)
    func paymentButton() -> PKPaymentButton
}

class ApplePayService: NSObject, ApplePayServiceType {
    
    public static let appSvc = ApplePayService()
    
    // MARK: Private vars
    private let supportedPaymentNetworks: [PKPaymentNetwork] = [.amex, .visa, .masterCard, .discover]
    
    // MARK: Public Methods
    func isDeviceCompatible() -> Bool {
        PKPaymentAuthorizationController.canMakePayments()
    }
    
    func isDeviceSetUp() -> Bool {
        PKPaymentAuthorizationController.canMakePayments(usingNetworks: supportedPaymentNetworks, capabilities: .capabilityCredit)
    }
    
    func paymentButton() -> PKPaymentButton {
        var buttonStyle = PKPaymentButtonStyle.black
        if #available(iOS 12.0, *) {
            if UIScreen.main.traitCollection.userInterfaceStyle == UIUserInterfaceStyle.dark {
                buttonStyle = .whiteOutline
            }
        }
        
        var buttonType = PKPaymentButtonType.setUp
        if self.isDeviceSetUp() {
            buttonType = .plain
        }
        
        return PKPaymentButton(paymentButtonType: buttonType, paymentButtonStyle: buttonStyle)
    }
    
    func showPaymentSheet(depositAmount: Float) {
        if self.isDeviceSetUp() {
            let request = PKPaymentRequest()
            request.currencyCode = "USD"
            request.countryCode = "US"
            request.merchantIdentifier = "merchant.com.twinspires.test"
            request.merchantCapabilities = .capabilityCredit
            request.supportedNetworks = supportedPaymentNetworks
            request.paymentSummaryItems = [
                PKPaymentSummaryItem.init(label: "Deposit Amount", amount: NSDecimalNumber(value: depositAmount)),
                PKPaymentSummaryItem.init(label: "Transaction Fees", amount: NSDecimalNumber(value: Float("5")!)),
                PKPaymentSummaryItem.init(label: "TwinSpires", amount: NSDecimalNumber(value: Float(depositAmount + Float("5")!)))
            ]
            request.requiredBillingContactFields = [ PKContactField.postalAddress ]
            
            let paymentRequest = PKPaymentAuthorizationController(paymentRequest: request)
            paymentRequest.delegate = self
            paymentRequest.present(completion: nil)
        } else {
            let passLib = PKPassLibrary()
            passLib.openPaymentSetup()
        }
    }
}

extension ApplePayService: PKPaymentAuthorizationControllerDelegate {
    func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
        controller.dismiss(completion: nil)
    }
    
    func paymentAuthorizationController(_ controller: PKPaymentAuthorizationController, didAuthorizePayment payment: PKPayment, handler completion: @escaping (PKPaymentAuthorizationResult) -> Void) {
        completion(PKPaymentAuthorizationResult.init(status: PKPaymentAuthorizationStatus.success, errors: nil))
    }
}
