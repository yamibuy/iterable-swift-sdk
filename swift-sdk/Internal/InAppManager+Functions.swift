//
//  Created by Tapash Majumder on 5/30/19.
//  Copyright © 2019 Iterable. All rights reserved.
//

import Foundation

enum MessagesProcessorResult {
    case show(message: IterableInAppMessage, messagesMap: OrderedDictionary<String, IterableInAppMessage>)
    case noShow(messagesMap: OrderedDictionary<String, IterableInAppMessage>)
}

struct MessagesProcessor {
    init(inAppDelegate: IterableInAppDelegate,
         inAppDisplayChecker: InAppDisplayChecker,
         messagesMap: OrderedDictionary<String, IterableInAppMessage>) {
        ITBInfo()
        
        self.inAppDelegate = inAppDelegate
        self.inAppDisplayChecker = inAppDisplayChecker
        self.messagesMap = messagesMap
    }
    
    mutating func processMessages(currentMessage:IterableInAppMessage? = nil) -> MessagesProcessorResult {
        ITBDebug()
        
      switch processNextMessage(currentMessage:currentMessage) {
          case let .show(message):
              updateMessage(message, didProcessTrigger: true, consumed: !message.saveToInbox)
              return .show(message: message, messagesMap: messagesMap)
          case let .skip(message):
              updateMessage(message, didProcessTrigger: true)
              messageSkippedHandler(message)
              return processMessages()
          case .none, .wait:
              return .noShow(messagesMap: messagesMap)
      case .next(let message):
                      return processMessages(currentMessage:message)
          }
    }
    
    private enum ProcessNextMessageResult {
        case show(IterableInAppMessage)
        case skip(IterableInAppMessage)
        case none
        case wait
        case next(IterableInAppMessage) // 当前消息不展示 找下一条

    }
    
   private func processNextMessage(currentMessage:IterableInAppMessage? = nil) -> ProcessNextMessageResult {
        ITBDebug()
        
        guard let message = getFirstProcessableTriggeredMessage(currentMessage:currentMessage) else {
            ITBDebug("No message to process, totalMessages: \(messagesMap.values.count)") //ttt
            return .none
        }
        
        ITBDebug("processing message with id: \(message.messageId)")
        
        if inAppDisplayChecker.isOkToShowNow(message: message) {
          ITBDebug("isOkToShowNow")
          let t = inAppDelegate.onNew(message: message)
          if t == .show {
            ITBDebug("delegete returned show")
            return .show(message)
          } else if t == .next{
            return .next(message)
          }else {
            ITBDebug("delegate returned skip")
            return .skip(message)
          }
        } else {
          ITBDebug("Not ok to show now")
          return .wait
        }
    }
    
    private func getFirstProcessableTriggeredMessage(currentMessage:IterableInAppMessage? = nil) -> IterableInAppMessage? {
      
      if let currentMessage = currentMessage{
        if let index = messagesMap.values.firstIndex(of: currentMessage){
          return messagesMap.values.dropFirst(index + 1).filter({ message in
            if let d = message.expiresAt{
              return d > Date()
            }
            return true
          }).filter(MessagesProcessor.isProcessableTriggeredMessage).first
        }
      }
      
      return messagesMap.values.filter({ message in
        if let d = message.expiresAt{
          return d > Date()
        }
        return true
      }).filter(MessagesProcessor.isProcessableTriggeredMessage).first
    }
    
    private static func isProcessableTriggeredMessage(_ message: IterableInAppMessage) -> Bool {
        return message.didProcessTrigger == false && message.trigger.type == .immediate
    }
    
    private mutating func updateMessage(_ message: IterableInAppMessage, didProcessTrigger: Bool? = nil, consumed: Bool? = nil) {
        ITBDebug()
        
        let toUpdate = message
        
        if let didProcessTrigger = didProcessTrigger {
            toUpdate.didProcessTrigger = didProcessTrigger
        }
        
        if let consumed = consumed {
            toUpdate.consumed = consumed
        }
        
        messagesMap.updateValue(toUpdate, forKey: message.messageId)
    }
    
    private let inAppDelegate: IterableInAppDelegate
    private let inAppDisplayChecker: InAppDisplayChecker
    private var messagesMap: OrderedDictionary<String, IterableInAppMessage>
    
    // message skip callback
    var messageSkippedHandler:(IterableInAppMessage)->() = {_ in}
}

struct MergeMessagesResult {
    let inboxChanged: Bool
    let messagesMap: OrderedDictionary<String, IterableInAppMessage>
}

/// Merges the results and determines whether inbox changed needs to be fired.
struct MessagesObtainedHandler {
    init(messagesMap: OrderedDictionary<String, IterableInAppMessage>, messages: [IterableInAppMessage]) {
        ITBInfo()
        self.messagesMap = messagesMap
        self.messages = messages
    }
    
    mutating func handle() -> MergeMessagesResult {
        // Remove messages that are no present in server
        let deletedInboxCount = removeDeletedMessages(messagesFromServer: messages)
        
        // add new ones
        let addedInboxCount = addNewMessages(messagesFromServer: messages)
        
      
        // 将直播消息放于数组最前
        var temp = messagesMap
        temp.sortKeys { keys  in
          
          return keys.sorted { (k1, k2)  in
            guard let m1 = messagesMap[k1], let m2 = messagesMap[k2] else{
              return true
            }
            
            if m1.isYamiLiveMessage,!m2.isYamiLiveMessage{
              return true
            }else if !m1.isYamiLiveMessage,m2.isYamiLiveMessage{
              return false
            }else if m1.isYamiLiveMessage,m2.isYamiLiveMessage{
              if let d1 = m1.createdAt ,let d2 = m1.createdAt{
                return d1 > d2
              }
              return m1.campaignId > m2.campaignId
            }else{
              return true
            }
          }
        }
        messagesMap = temp
      
        return MergeMessagesResult(inboxChanged: deletedInboxCount + addedInboxCount > 0,
                                   messagesMap: messagesMap)
    }
    
    // return count of deleted inbox messages
    private mutating func removeDeletedMessages(messagesFromServer messages: [IterableInAppMessage]) -> Int {
        var inboxCount = 0
        let removedMessages = getRemovedMessages(messagesFromServer: messages)
        
        removedMessages.forEach {
            if $0.saveToInbox == true {
                inboxCount += 1
            }
            
            messagesMap.removeValue(forKey: $0.messageId)
        }
        
        return inboxCount
    }
    
    // given `messages` coming for server, find messages that need to be removed
    private func getRemovedMessages(messagesFromServer messages: [IterableInAppMessage]) -> [IterableInAppMessage] {
        return messagesMap.values.reduce(into: [IterableInAppMessage]()) { result, message in
            if !messages.contains(where: { $0.messageId == message.messageId }) {
                result.append(message)
            }
        }
    }
    
    // returns count of inbox messages (save to inbox)
    private mutating func addNewMessages(messagesFromServer messages: [IterableInAppMessage]) -> Int {
        var inboxCount = 0
        messages.forEach { message in
            if !messagesMap.contains(where: { $0.key == message.messageId }) {
                if message.saveToInbox == true {
                    inboxCount += 1
                }
                
                messagesMap[message.messageId] = message
                
                IterableAPI.internalImplementation?.track(inAppDelivery: message)
            }
        }
        
        return inboxCount
    }
    
    private var messagesMap: OrderedDictionary<String, IterableInAppMessage>
    private let messages: [IterableInAppMessage]
}
