//
//  DeviceRaisedToEarListener.swift
//  AudioPOC
//
//  Created by Vitor Bryan on 22/03/22.
//

import Foundation
import UIKit
import CoreMotion

class DeviceRaisedToEarListener: NSObject {
    let deviceQueue = OperationQueue()
    let motionManager = CMMotionManager()
    var vertical: Bool = false
    
    private(set) var isRaisedToEar: Bool = false {
        didSet {
            if oldValue != self.isRaisedToEar {
                self.stateChanged?(self.isRaisedToEar)
            }
        }
    }
    var stateChanged:((_ isRaisedToEar: Bool)->())? = nil
    
    override init() {
        super.init()
        self.setupMotionManager()
    }
    
    func setupMotionManager() {
        self.motionManager.deviceMotionUpdateInterval = 5.0 / 60.0

        // Only listen for proximity changes if the device is held vertically
        self.motionManager.startDeviceMotionUpdates(using: CMAttitudeReferenceFrame.xArbitraryZVertical, to: self.deviceQueue) { (motion, error) in
            if let motion = motion {
                self.vertical = (motion.gravity.z > -0.4 && motion.gravity.z < 0.4 && motion.gravity.y < -0.7)
            }
        }
    }
    
    func startListening() {
        UIDevice.current.isProximityMonitoringEnabled = true
        NotificationCenter.default.addObserver(self, selector: #selector(handleProximityChange), name: UIDevice.proximityStateDidChangeNotification, object: nil)
    }

    func stopListening() {
        UIDevice.current.isProximityMonitoringEnabled = false
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc
    func handleProximityChange(notification: NSNotification) {
        self.isRaisedToEar = UIDevice.current.proximityState && self.vertical
    }

    deinit {
        self.stopListening()
    }
}
