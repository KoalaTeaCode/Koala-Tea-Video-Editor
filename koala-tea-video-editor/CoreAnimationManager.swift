//
//  CoreAnimationManager.swift
//  koala-tea-video-editor
//
//  Created by Craig Holliday on 1/11/18.
//  Copyright © 2018 Koala Tea. All rights reserved.
//

import Foundation
import UIKit

// Core Animation takes in
// Params: 
// And
// Returns: Any CA Animation type

public class CoreAnimationManager {
    
}

extension CALayer {
    //@TODO: add completion?
    public func showLayer(at beginTime: Double, till endTime: Double? = nil) {
        let animation = CABasicAnimation()
        animation.keyPath = CALayerGeometryKeyPaths.opacity.key
        animation.beginTime = beginTime
        animation.duration = 0
        animation.toValue = 1
        animation.speed = 10
        animation.fillMode = kCAFillModeForwards
        animation.isRemovedOnCompletion = false
        
        self.addWithKeyname(animation: animation)
        
        if let endTime = endTime {
            self.hideLayer(at: endTime)
        }
    }
    
    public func hideLayer(at beginTime: Double) {
        let animation = CABasicAnimation()
        animation.keyPath = CALayerGeometryKeyPaths.opacity.key
        animation.beginTime = beginTime
        animation.duration = 0
        animation.toValue = 0
        animation.speed = 10
        animation.fillMode = kCAFillModeForwards
        animation.isRemovedOnCompletion = false
        
        self.addWithKeyname(animation: animation)
    }
    
    // Changes X, Y, Z scale to value * original size
    public func changeAllScale(to toValue: NSNumber, beginTime: Double, duration: Double) {
        let animation = CABasicAnimation()
        animation.keyPath = CALayerGeometryKeyPaths.scale.key
        animation.beginTime = beginTime
        animation.duration = duration
        animation.toValue = toValue
        animation.speed = 1
        
        if duration == 0 {
            animation.speed = 10
        }
        
        animation.fillMode = kCAFillModeForwards
        animation.isRemovedOnCompletion = false
        
        self.addWithKeyname(animation: animation)
    }
    
    // Changes X scale to value * original size
    public func changeScaleX(to toValue: NSNumber, beginTime: Double, duration: Double) {
        let animation = CABasicAnimation()
        animation.keyPath = CALayerGeometryKeyPaths.scaleX.key
        animation.beginTime = beginTime
        animation.duration = duration
        animation.toValue = toValue
        animation.speed = 1
        
        if duration == 0 {
            animation.speed = 10
        }
        
        animation.fillMode = kCAFillModeForwards
        animation.isRemovedOnCompletion = false
        
        self.addWithKeyname(animation: animation)
    }
    
    // Changes Y scale to value * original size
    public func changeScaleY(to toValue: NSNumber, beginTime: Double, duration: Double) {
        let animation = CABasicAnimation()
        animation.keyPath = CALayerGeometryKeyPaths.scaleY.key
        animation.beginTime = beginTime
        animation.duration = duration
        animation.toValue = toValue
        animation.speed = 1
        
        if duration == 0 {
            animation.speed = 10
        }
        
        animation.fillMode = kCAFillModeForwards
        animation.isRemovedOnCompletion = false
        
        self.addWithKeyname(animation: animation)
    }
    
    // Changes X and Y position to point
    public func changePosition(toPoint toValue: CGPoint, beginTime: Double, duration: Double) {
        let animation = CABasicAnimation()
        animation.keyPath = CALayerGeometryKeyPaths.position.key
        animation.beginTime = beginTime
        animation.duration = duration
        animation.toValue = toValue
        animation.speed = 1
        
        if duration == 0 {
            animation.speed = 10
        }
        
        animation.fillMode = kCAFillModeForwards
        animation.isRemovedOnCompletion = false
        
        self.addWithKeyname(animation: animation)
    }
    //@TODO: Change this to begin and end time
    // Changes X position to value
    public func changePositionX(to toValue: NSNumber, beginTime: Double, duration: Double) {
        let animation = CABasicAnimation()
        animation.keyPath = CALayerGeometryKeyPaths.positionX.key

        animation.beginTime = beginTime
        animation.duration = duration
        animation.toValue = toValue
        animation.speed = 1
        
        if duration == 0 {
            animation.speed = 10
        }
        
        animation.fillMode = kCAFillModeForwards
        animation.isRemovedOnCompletion = false
        
        self.addWithKeyname(animation: animation)
    }
    
    // Changes Y position to value
    public func changePositionY(to toValue: NSNumber, beginTime: Double, duration: Double) {
        let animation = CABasicAnimation()
        animation.keyPath = CALayerGeometryKeyPaths.positionY.key
        animation.beginTime = beginTime
        animation.duration = duration
        animation.toValue = toValue
        animation.speed = 1
        
        if duration == 0 {
            animation.speed = 10
        }
        
        animation.fillMode = kCAFillModeForwards
        animation.isRemovedOnCompletion = false
        
        self.addWithKeyname(animation: animation)
    }
}

extension CABasicAnimation {
    public func getCABasicAnimationForVideoExport() -> CABasicAnimation {
        let animation = CABasicAnimation()
        animation.keyPath = self.keyPath
        animation.beginTime = self.beginTime - CACurrentMediaTime()
        animation.duration = self.duration - CACurrentMediaTime()
        animation.toValue = self.toValue
        animation.speed = 1

        if duration == 0 {
            animation.speed = 10
        }

        animation.fillMode = self.fillMode
        animation.isRemovedOnCompletion = self.isRemovedOnCompletion

        return animation
    }
}

//////////////////////////
//MARK: CALayer Helpers//
/////////////////////////
extension CALayer {
    fileprivate func addWithKeyname(animation: CABasicAnimation) {
        guard let keyname = self.getBasicAnimationKeypath(for: animation) else {
            assertionFailure("Can't get no keyname")
            return
        }
        
        self.add(animation, forKey: keyname)
    }
    
    fileprivate func getBasicAnimationKeypath(for animation: CABasicAnimation) -> String? {
        // Find keypath
        guard let keypath = animation.keyPath else {
            assertionFailure("No keypath set")
            return nil
        }
        
        let keyname = keypath
        
        var number: Int?
        if let keys = self.animationKeys() {
            let these = keys.filter({ $0.contains(keyname) })
            // Keyname is taken so add a number to the key
            if !these.isEmpty {
                number = keys.count
            }
        }
        
        var numberString = ""
        if let v = number {
            numberString = "\(v)"
        }
        
        return keyname + numberString
    }
}
