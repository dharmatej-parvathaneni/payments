//
//  ViewController.swift
//  Payments
//
//  Created by Dharmatej Parvathaneni on 4/24/20.
//  Copyright © 2020 twinspires. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    // MARK:  Oulets
    @IBOutlet var amount: UITextField!
    
    @IBOutlet weak var fcmTokenMessage: UILabel!
    
    // MARK: private const
    private let applePayService = ApplePayService.appSvc
    
    // MARK: private var
    private var applePayButton: UIButton!
    
    // MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        NSLog("ViewController: viewDidLoad..!!!")
        
        // Listener to identify the token refresh
        NotificationCenter.default.addObserver(self, selector: #selector(self.displayFCMToken(notification:)), name: Notification.Name("FCMToken"), object: nil)
        
        // Listener to read the Background Notification Data
        NotificationCenter.default.addObserver(self, selector: #selector(self.displayNotificationData(notification:)), name: Notification.Name("DataMsgBackEnd"), object: nil)
        
        // Create Payment Button
        self.createPaymentButton()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NSLog("View Did Appear")
        
        NotificationCenter.default.addObserver(self, selector: #selector(appEnteredForeGround(_:)), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NSLog("View DID  Disappear")
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: Obj-C funcs
    @objc private func submitApplePay() {
        let depAmt = Float(amount.text!)
        applePayService.showPaymentSheet(depositAmount: depAmt!)
    }
    
    @objc func appEnteredForeGround(_ notification: Notification) {
        NSLog("appEnteredForeGround() Called....!!")
        self.createPaymentButton()
    }
    
    @objc func displayFCMToken(notification: NSNotification) {
        guard let userInfo = notification.userInfo else { return }
        if let fcmToken = userInfo["token"] as? String {
            if !fcmToken.isEmpty {
                self.fcmTokenMessage.text = "Token is Available"
            }
        }
    }
    
    @objc func displayNotificationData(notification: NSNotification) {
        // UnSubscribe from Topic
        self.applePayService.unSubscribeFromTopic()
        
        guard let userInfo = notification.userInfo else { return }
        
        let txData = userInfo as NSDictionary as! [String: AnyObject]
        
        let alertTitle = txData["TxType"] as! String
        let amount = txData["Amount"] as! String
        let txType = txData["TxPayType"] as! String
        
        var alert = UIAlertController(title: alertTitle, message: "\(String(describing: txType)) deposit for \(String(describing: amount)) failed", preferredStyle: UIAlertController.Style.alert)
        
        if txData["TxStatus"] as! String == "SUCCESS" {
            alert = UIAlertController(title: alertTitle, message: "\(String(describing: txType)) deposit for \(String(describing: amount)) is successful", preferredStyle: UIAlertController.Style.alert)
        }
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    // MARK: private methods
    private func createPaymentButton() {
        if self.applePayButton != nil {
            self.applePayButton.removeFromSuperview()
        }
        
        if applePayService.isDeviceCompatible() {
            self.applePayButton = applePayService.paymentButton()
            self.applePayButton.widthAnchor.constraint(equalToConstant: 150.0).isActive = true;
            self.applePayButton.heightAnchor.constraint(equalToConstant: 50.0).isActive = true;
            self.applePayButton.addTarget(self, action: #selector(submitApplePay), for: .touchUpInside)
            self.applePayButton.translatesAutoresizingMaskIntoConstraints = false
            
            view.addSubview(self.applePayButton)
            view.addConstraint(NSLayoutConstraint(item: self.applePayButton!, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1, constant: 0))
            view.addConstraint(NSLayoutConstraint(item: self.applePayButton!, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 1, constant: 0))
        }
    }
}
