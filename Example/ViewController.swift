//
//  ViewController.swift
//  Example
//
//  Created by Parvinder-SFIN485 on 07/06/19.
//  Copyright © 2019 Sourcefuse. All rights reserved.
//

import UIKit
import ChatClient

class ViewController: UIViewController {

    override func viewDidLoad() {
        Configuration.shared.currentUser = DriverMockUser()
        let hints = ["Hi","How's it going","How are you doing", "What's new?", "What's about you", "Hey!! What's up", "How's your day?"]
        Configuration.shared.hints.append(contentsOf: hints)
        super.viewDidLoad()
        
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    @IBAction func push(_ sender: Any) {
        let controller  = ChatViewController.Navigator.push(from: self, title: "Message Title", withMessages: [
            ChatMessage(text: "Initial text 1",sender: RiderMockUser()),
            ChatMessage(text: "Initial text 2",sender: RiderMockUser())])
        controller.messageSentCallback = { message in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                if controller.view.window != nil {
                    let status = arc4random() % 3 == 0 ? MessageDeliveryStatus.delivered : MessageDeliveryStatus.error
                    controller.updateMessageStatus(messageId: message.messageId, status: status)
                }
            })
        }
        
        controller.didCloseCallback = {
            print("close callback")
        }
        
        Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { (timer) in
            if controller.view.window != nil {
                controller.insertMessage(ChatMessage(text: "Rider Message ",sender : RiderMockUser()))
            }
            else {
                timer.invalidate()
            }
        }
    }
    
    
    @IBAction func present(_ sender: Any) {
        let controller  = ChatViewController.Navigator.present(on: self, title: "Message Title", withMessages: [
            ChatMessage(text: "Initial text",sender: RiderMockUser())],barTintColor: UIColor.green, tintColor: UIColor.red, titleColor: .white)
        controller.messageSentCallback = { message in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                if controller.presentingViewController != nil {
                    let status = arc4random() % 3 == 0 ? MessageDeliveryStatus.delivered : MessageDeliveryStatus.error
                    controller.updateMessageStatus(messageId: message.messageId, status: status)
                }
            })
        }
        
        controller.didCloseCallback = {
            print("close callback")
        }
        
        Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { (timer) in
            if controller.presentingViewController != nil {
                controller.insertMessage(ChatMessage(text: "Rider Message ",sender : RiderMockUser()))
            }
            else {
                timer.invalidate()
            }
        }
    }

}


