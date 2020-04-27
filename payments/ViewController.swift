//
//  ViewController.swift
//  Payments
//
//  Created by Dharmatej Parvathaneni on 4/24/20.
//  Copyright © 2020 twinspires. All rights reserved.
//

import UIKit
import PassKit

class ViewController: UIViewController {
    
    @IBOutlet var amount: UITextField!
    
    var applePayService: ApplePayServiceType!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        applePayService = ApplePayService()
        
        // Create Payment Button
        if applePayService.isDeviceCompatible() {
            let applePayButton = applePayService.paymentButton()
            applePayButton.addTarget(self, action: #selector(submitApplePay(_:)), for: .touchUpInside)
            applePayButton.translatesAutoresizingMaskIntoConstraints = false
            
            view.addSubview(applePayButton)
            view.addConstraint(NSLayoutConstraint(item: applePayButton, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1, constant: 0))
            view.addConstraint(NSLayoutConstraint(item: applePayButton, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 1, constant: 0))
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        applePayService = nil
    }
    
    @objc private func submitApplePay(_ sender: PKPaymentButton) {
//        let passLibrary = PKPassLibrary()
//        passLibrary.openPaymentSetup()
        
        let depositAmount = Float(amount.text!)
        applePayService.showPaymentSheet(viewCtrl: self, depositAmount: NSDecimalNumber(value: depositAmount!))
    }
    
}
