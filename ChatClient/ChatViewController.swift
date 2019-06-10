//
//  ChatViewControlletr.swift
//  ChatClient
//
//  Created by Parvinder-SFIN485 on 07/06/19.
//  Copyright © 2019 Sourcefuse. All rights reserved.
//

import UIKit
import MessageKit
import InputBarAccessoryView

public typealias ChatUserType = SenderType

public protocol ChatMessageType : MessageType{
    var messageStatus:MessageDeliveryStatus {get set}
}
public enum MessageDeliveryStatus {
    case delivered
    case error
    case none
}


public class Configuration {
    public private(set) static var shared = Configuration()
    private init(){}
    open var currentUser: ChatUserType!
    public var hints = [String]()
    private var _messageFontName: String?
    open var closeButtonTitle = "Close"
    open var deliveredMessage = "Delivered"
    open var sendButtonTitle = "Send"
    open var deliverFailureMessage = "Error"
    open var sendingMessage = "Sending..."
    
    public var messageFontName: String? {
        get {
            return _messageFontName
        }
        set {
            _messageFontName = newValue
        }
    }
    
}

open class ChatViewController: MessagesViewController, MessagesDataSource {
    
    open private(set) var chatMessages = [ChatMessageType]()
    
    public var messageSentCallback: ((ChatMessageType) -> ())?
    
    public var didCloseCallback: (()->())?
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        assert(Configuration.shared.currentUser != nil, "Initialize the Configuration for current user")
        messageInputBar.setStackViewItems([mInputItem()], forStack: .top, animated: false)
        messagesCollectionView.messagesDataSource = self
        scrollsToBottomOnKeyboardBeginsEditing = true
        maintainPositionOnKeyboardFrameChanged = true
        messageInputBar.delegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messagesLayoutDelegate = self
        messageInputBar.separatorLine.height = 0
        messageInputBar.sendButton.setTitle(Configuration.shared.sendButtonTitle, for: UIControl.State.normal)
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if self.presentingViewController != nil {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem.init(title: Configuration.shared.closeButtonTitle, style: UIBarButtonItem.Style.plain, target: self, action: #selector(dismissSelf))
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.messageInputBar.inputTextView.becomeFirstResponder()
        }
        
    }
    
    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if self.isMovingFromParent {
            didCloseCallback?()
        }
    }
    
    @objc
    private func dismissSelf() {
        self.didCloseCallback?()
        self.dismiss(animated: true, completion: nil)
    }
    
    public func currentSender() -> SenderType {
        return Configuration.shared.currentUser
    }
    
    public func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return chatMessages[indexPath.section]
    }
    
    public func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return chatMessages.count
    }
    
    public func cellBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        guard let chatMessage = message as? ChatMessage else { return nil }
        switch chatMessage.messageStatus {
        case .delivered:
            return NSAttributedString(string: Configuration.shared.deliveredMessage, attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 10), NSAttributedString.Key.foregroundColor: UIColor.darkGray])
        case .error:
            return NSAttributedString(string: Configuration.shared.deliverFailureMessage, attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 10), NSAttributedString.Key.foregroundColor: UIColor.red])
        default:
            return nil
            
        }
        
    }
    
    public func cellBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 14
    }
    
    public func updateMessageStatus(messageId:String, status:MessageDeliveryStatus) {
        
        DispatchQueue.global().async { [weak self] in
            var _offset:Int?
            self?.chatMessages.enumerated().forEach({ (arg0) in
                let (offset, element) = arg0
                if (element.messageId == messageId) {
                    _offset = offset
                    return
                }
            })
            
            if let offset = _offset, self?.isFromCurrentSender(message: self!.chatMessages[offset]) ?? false {
                self?.chatMessages[offset].messageStatus = status
                DispatchQueue.main.async {
                    self?.messagesCollectionView.performBatchUpdates({
                        if (self?.chatMessages.count ?? 0) >= 1 {
                            self?.messagesCollectionView.reloadSections([offset])
                        }
                    }, completion: { [weak self] _ in
                        if self?.isLastSectionVisible() == true {
                            self?.messagesCollectionView.scrollToBottom(animated: true)
                        }
                    })
                }
            }
        }
    }
    
    public func insertMessage(_ message: ChatMessageType) {
        chatMessages.append(message)
        // Reload last section to update header/footer labels and insert a new one
        
        messagesCollectionView.performBatchUpdates({
            messagesCollectionView.insertSections([chatMessages.count - 1])
            if chatMessages.count >= 2 {
                messagesCollectionView.reloadSections([chatMessages.count - 2])
            }
        }, completion: { [weak self] _ in
            if self?.isLastSectionVisible() == true {
                self?.messagesCollectionView.scrollToBottom(animated: true)
            }
            
        })
    }
    
    func isLastSectionVisible() -> Bool {
        
        guard !chatMessages.isEmpty else { return false }
        
        let lastIndexPath = IndexPath(item: 0, section: chatMessages.count - 1)
        
        return messagesCollectionView.indexPathsForVisibleItems.contains(lastIndexPath)
    }
    
    public func isFromCurrentSender(message: MessageType) -> Bool {
        return message.sender.senderId == Configuration.shared.currentUser.senderId
    }
    
}



extension ChatViewController : InputBarAccessoryViewDelegate {
    public func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        
        // Here we can parse for which substrings were autocompleted
        let attributedText = messageInputBar.inputTextView.attributedText!
        let range = NSRange(location: 0, length: attributedText.length)
        attributedText.enumerateAttribute(.autocompleted, in: range, options: []) { (_, range, _) in
            
            let substring = attributedText.attributedSubstring(from: range)
            let context = substring.attribute(.autocompletedContext, at: 0, effectiveRange: nil)
            print("Autocompleted: `", substring, "` with context: ", context ?? [])
        }
        
        let message = inputBar.inputTextView.text
        messageInputBar.inputTextView.text = ""
        messageInputBar.invalidatePlugins()
        
        // Send button activity animation
        messageInputBar.sendButton.startAnimating()
        messageInputBar.inputTextView.placeholder = Configuration.shared.sendingMessage //"Sending..."
        self.messageInputBar.sendButton.stopAnimating()
        self.messageInputBar.inputTextView.placeholder = "Aa"
        let chatMessage = ChatMessage(text: message ?? "")
        self.insertMessage(chatMessage)
        self.messageSentCallback?(chatMessage)
        self.messagesCollectionView.scrollToBottom(animated: true)
        
    }
}

extension ChatViewController : MessagesDisplayDelegate {
    public func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        let tail: MessageStyle.TailCorner = isFromCurrentSender(message: message) ? .bottomRight : .bottomLeft
        print(message.sender.senderId ,message.sender.displayName, message.kind)
        return .bubbleTail(tail, .curved)
    }
    
    
}

extension ChatViewController : MessagesLayoutDelegate {
    public func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        var frameworkBundle = Bundle(for: ChatViewController.self)
        if let bundle = Bundle.init(url: frameworkBundle.resourceURL!.appendingPathComponent("Resource.bundle")) {
            frameworkBundle = bundle
        }
        let avatar1 = UIImage(named: "avatar", in: frameworkBundle, compatibleWith: nil)
        let avatar2 = UIImage(named: "avatar1", in: frameworkBundle, compatibleWith: nil)
        let avatar = isFromCurrentSender(message: message) ?
            avatar1 : avatar2
        avatarView.set(avatar: Avatar(image: avatar, initials: ""))
    }
}

public struct RiderMockUser : SenderType {
    public var senderId: String
    public var displayName: String
    
    public init() {
        self.senderId = "11111"
        self.displayName = "Mock User 1"
    }
}

public struct DriverMockUser : SenderType {
    public var senderId: String
    public var displayName: String
    
    public init() {
        self.senderId = "22222"
        self.displayName = "Mock User 2"
    }
}

public class ChatMessage : ChatMessageType {
    
    public var messageStatus: MessageDeliveryStatus = .none
    public var sender: SenderType
    public var messageId: String
    public var sentDate: Date
    public var kind: MessageKind
    
    public init(text:String, sender: SenderType = Configuration.shared.currentUser) {
        
        self.sender = sender
        messageId = UUID.init().uuidString
        sentDate = Date()
        kind = .text(text)
    }
}


extension ChatViewController {
    public class Navigator {
        private init(){}
        
        public static func push(from:UIViewController,title:String ,withMessages messages:[ChatMessageType]) -> ChatViewController {
            let controller = ChatViewController()
            controller.chatMessages = messages
            controller.title = title
            from.navigationController?.pushViewController(controller, animated: true)
            return controller
        }
        
        public static func present(on:UIViewController,title:String ,withMessages messages:[ChatMessageType], barTintColor: UIColor? = nil, tintColor: UIColor? = nil, titleColor: UIColor? = nil ) -> ChatViewController {
            let controller = ChatViewController()
            controller.chatMessages = messages
            controller.title = title
            let navigationController = UINavigationController.init(rootViewController: controller)
            navigationController.navigationBar.barTintColor = barTintColor
            if let tintColor = tintColor {
                navigationController.navigationBar.tintColor = tintColor
                
            }
            if let titleColor = titleColor {
                navigationController.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: titleColor]
            }
            on.present(navigationController, animated: true, completion: nil)
            return controller
        }
    }
}
