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
    func showPaymentSheet(viewCtrl: UIViewController, depositAmount: NSDecimalNumber)
    func paymentButton() -> PKPaymentButton
}

class ApplePayService: NSObject, ApplePayServiceType {
    
    // MARK: Private vars
    private let supportedPaymentNetworks: [PKPaymentNetwork] = [.amex, .visa, .masterCard]
    
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
                buttonStyle = .white
            }
        }
        
        var buttonType = PKPaymentButtonType.setUp
        if self.isDeviceSetUp() {
            buttonType = .plain
        }
        
        return PKPaymentButton(paymentButtonType: buttonType, paymentButtonStyle: buttonStyle)
    }
    
    func showPaymentSheet(viewCtrl: UIViewController, depositAmount: NSDecimalNumber) {
        if self.isDeviceSetUp() {
            let request = PKPaymentRequest()
            request.currencyCode = "USD"
            request.countryCode = "US"
            request.merchantIdentifier = "merchant.com.twinspires.test"
            request.merchantCapabilities = .capabilityCredit
            request.supportedNetworks = supportedPaymentNetworks
            request.paymentSummaryItems = [PKPaymentSummaryItem.init(label: "Deposit Amount", amount: depositAmount)]
            
            guard let paymentCtrl = PKPaymentAuthorizationViewController(paymentRequest: request) else {
                return
            }
            paymentCtrl.delegate = self
            viewCtrl.present(paymentCtrl, animated: true, completion: nil)
        } else {
            let passLib = PKPassLibrary()
            passLib.openPaymentSetup()
        }
    }
}

extension ApplePayService: PKPaymentAuthorizationViewControllerDelegate {
    func paymentAuthorizationViewControllerDidFinish(_ controller: PKPaymentAuthorizationViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController, didAuthorizePayment payment: PKPayment, handler completion: @escaping (PKPaymentAuthorizationResult) -> Void) {
//        let token = payment.token
        controller.dismiss(animated: true, completion: nil)
    }
    
}
