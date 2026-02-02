//
//  TimerManager.swift
//  SafeTone
//
//  Manages call duration timer using Combine Timer.publish
//

import Foundation
import Combine

class TimerManager: ObservableObject {
    @Published var callDuration: Int = 0 // seconds
    
    private var timer: AnyCancellable?
    
    var formattedDuration: String {
        let minutes = callDuration / 60
        let seconds = callDuration % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    func start() {
        callDuration = 0
        timer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.callDuration += 1
            }
    }
    
    func stop() {
        timer?.cancel()
        timer = nil
        callDuration = 0
    }
}
