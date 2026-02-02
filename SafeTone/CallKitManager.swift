//
//  CallKitManager.swift
//  SafeTone
//
//  CallKit integration with CXProviderDelegate for handling incoming calls
//

import Foundation
import CallKit
import AVFoundation
import Combine

class CallKitManager: NSObject, ObservableObject {
    static let shared = CallKitManager()
    
    @Published var isCallAnswered = false {
        willSet { objectWillChange.send() }
    }
    @Published var currentCallerName: String = "" {
        willSet { objectWillChange.send() }
    }
    @Published var verificationStatus: CallVerificationStatus = .analyzing {
        willSet { objectWillChange.send() }
    }
    
    private let provider: CXProvider
    private let callController = CXCallController()
    
    override init() {
        let configuration = CXProviderConfiguration()
        configuration.supportsVideo = true
        configuration.maximumCallGroups = 1
        configuration.maximumCallsPerCallGroup = 1
        configuration.supportedHandleTypes = [.phoneNumber]
        configuration.iconTemplateImageData = nil // Set your app icon
        
        provider = CXProvider(configuration: configuration)
        
        super.init()
        
        provider.setDelegate(self, queue: nil)
    }
    
    // MARK: - Incoming Call
    func reportIncomingCall(uuid: UUID, handle: String, hasVideo: Bool = false, completion: ((Error?) -> Void)? = nil) {
        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(type: .phoneNumber, value: handle)
        update.hasVideo = hasVideo
        update.localizedCallerName = handle
        
        provider.reportNewIncomingCall(with: uuid, update: update) { error in
            if error == nil {
                self.currentCallerName = handle
            }
            completion?(error)
        }
    }
    
    // MARK: - End Call
    func endCall(uuid: UUID) {
        let endCallAction = CXEndCallAction(call: uuid)
        let transaction = CXTransaction(action: endCallAction)
        
        callController.request(transaction) { error in
            if let error = error {
                print("Error ending call: \(error.localizedDescription)")
            } else {
                self.isCallAnswered = false
                self.currentCallerName = ""
            }
        }
    }
    
    // MARK: - Mock AI Detection
    /// Simulates AI voice detection after call starts
    func performAIDetection() {
        // In a real app, this would analyze audio in real-time
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            // Randomly verify or detect AI for demo purposes
            self.verificationStatus = Bool.random() ? .voiceVerified : .aiDetected
        }
    }
}

// MARK: - CXProviderDelegate
extension CallKitManager: CXProviderDelegate {
    func providerDidReset(_ provider: CXProvider) {
        // Handle provider reset
        isCallAnswered = false
        currentCallerName = ""
    }
    
    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        // Configure audio session
        configureAudioSession()
        
        // Answer the call
        DispatchQueue.main.async {
            self.isCallAnswered = true
            self.verificationStatus = .analyzing
        }
        
        // Start AI detection
        performAIDetection()
        
        // Fulfill the action
        action.fulfill()
    }
    
    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        DispatchQueue.main.async {
            self.isCallAnswered = false
            self.currentCallerName = ""
            self.verificationStatus = .analyzing
        }
        
        action.fulfill()
    }
    
    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        action.fulfill()
    }
    
    func provider(_ provider: CXProvider, perform action: CXSetHeldCallAction) {
        action.fulfill()
    }
    
    func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
        action.fulfill()
    }
    
    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        // Start audio
    }
    
    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        // Stop audio
    }
    
    // MARK: - Audio Session
    private func configureAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [])
            try audioSession.setActive(true)
        } catch {
            print("Failed to configure audio session: \(error.localizedDescription)")
        }
    }
}
