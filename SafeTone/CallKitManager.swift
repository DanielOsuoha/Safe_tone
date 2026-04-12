//
//  CallKitManager.swift
//  SafeTone
//
//  CallKit integration with CXProviderDelegate for handling incoming calls
//

import Foundation
import CallKit
import AVFoundation

final class CallKitManager: NSObject {
    static let shared = CallKitManager()

    private let callManager = CallManager.shared
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
                Task { @MainActor in
                    self.callManager.receiveIncomingCall(id: uuid, handle: handle, displayName: handle)
                }
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
                Task { @MainActor in
                    self.callManager.endCall()
                }
            }
        }
    }
}

// MARK: - CXProviderDelegate
extension CallKitManager: CXProviderDelegate {
    func providerDidReset(_ provider: CXProvider) {
        Task { @MainActor in
            callManager.endCall()
        }
    }
    
    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        configureAudioSession()

        Task { @MainActor in
            callManager.answerCall()
        }

        action.fulfill()
    }
    
    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        Task { @MainActor in
            callManager.endCall()
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
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [])
            try audioSession.setActive(true)
        } catch {
            print("Failed to configure audio session: \(error.localizedDescription)")
        }
    }
}
