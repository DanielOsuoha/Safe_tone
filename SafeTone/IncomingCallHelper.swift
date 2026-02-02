//
//  IncomingCallHelper.swift
//  SafeTone
//
//  Helper to simulate incoming calls for testing CallKit integration
//

import Foundation
import CallKit

extension CallKitManager {
    /// Simulates an incoming call for testing purposes
    /// Call this from your UI to test the call flow
    func simulateIncomingCall(from callerName: String) {
        let uuid = UUID()
        reportIncomingCall(uuid: uuid, handle: callerName) { error in
            if let error = error {
                print("Error reporting incoming call: \(error.localizedDescription)")
            } else {
                print("Incoming call from \(callerName) reported successfully")
            }
        }
    }
}
