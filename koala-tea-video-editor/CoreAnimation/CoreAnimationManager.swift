//
//  CoreAnimationManager.swift
//  koala-tea-video-editor
//
//  Created by Craig Holliday on 1/11/18.
//  Copyright © 2018 Koala Tea. All rights reserved.
//

import Foundation
import UIKit

extension CABasicAnimation {
    /// Animation to set opacity to 1 WITHOUT a begin time
    public class func showLayerAnimation() -> CABasicAnimation {
        let animation = CABasicAnimation()

        animation.keyPath = CALayerGeometryKeyPaths.opacity.key
        animation.duration = 0
        animation.toValue = 1
        animation.speed = 10
        animation.fillMode = kCAFillModeForwards
        animation.isRemovedOnCompletion = false

        return animation
    }

    /// Animation to set opacity to 0 WITHOUT a begin time
    public class func hideLayerAnimation() -> CABasicAnimation {
        let animation = CABasicAnimation()

        animation.keyPath = CALayerGeometryKeyPaths.opacity.key
        animation.duration = 0
        animation.toValue = 0
        animation.speed = 10
        animation.fillMode = kCAFillModeForwards
        animation.isRemovedOnCompletion = false

        return animation
    }

    /// Animation to set opacity to 1 WITH a begin time
    public class func showLayerAnimation(at beginTime: Double) -> CABasicAnimation {
        let animation = CABasicAnimation()

        animation.keyPath = CALayerGeometryKeyPaths.opacity.key
        animation.beginTime = beginTime
        animation.duration = 0
        animation.toValue = 1
        animation.speed = 10
        animation.fillMode = kCAFillModeForwards
        animation.isRemovedOnCompletion = false

        return animation
    }

    /// Animation to set opacity to 0 WITH a begin time but no Current Media
    public class func hideLayerAnimation(at beginTime: Double) -> CABasicAnimation {
        let animation = CABasicAnimation()

        animation.keyPath = CALayerGeometryKeyPaths.opacity.key
        animation.beginTime = beginTime
        animation.duration = 0
        animation.toValue = 0
        animation.speed = 10
        animation.fillMode = kCAFillModeForwards
        animation.isRemovedOnCompletion = false

        return animation
    }

//    public func getCABasicAnimationForVideoExport(currentMediaTime: Double) -> CABasicAnimation {
//        let animation = CABasicAnimation()
//        animation.keyPath = self.keyPath
//        animation.beginTime = self.beginTime - currentMediaTime
//        animation.duration = self.duration
//        animation.toValue = self.toValue
//        animation.speed = 1
//
//        // @TODO: Fix 0.25.
//        // For some reason the duration changes when going from layer on screen -> video ca layer
//        if self.duration <= 0 || self.duration <= 0.25 {
//            animation.speed = 10
//        }
//
//        animation.fillMode = self.fillMode
//        animation.isRemovedOnCompletion = self.isRemovedOnCompletion
//
//        return animation
//    }
}

//extension CALayer {
//    public func removeAnimationsCurrentMediaTimeFor(currentMediaTimeUsed: Double) {
//        guard let keys = self.animationKeys() else {
//            assertionFailure("no animation keys")
//            return
//        }
//        for key in keys {
//            guard let animation = self.animation(forKey: key) as? CABasicAnimation else {
//                //@TODO: Accept more than basic animation
//                assertionFailure("no animation")
//                return
//            }
//            self.removeAnimation(forKey: key)
//
//            self.add(animation.getCABasicAnimationForVideoExport(currentMediaTime: currentMediaTimeUsed), forKey: key)
//        }
//
//        return
//    }
//}

extension CALayer {
    public func showLayer(at beginTime: Double, till endTime: Double? = nil) {
        let animation = CABasicAnimation.showLayerAnimation(at: beginTime)

        self.addWithKeyname(animation: animation)
        
        if let endTime = endTime {
            self.hideLayer(at: endTime)
        }
    }
    
    public func hideLayer(at beginTime: Double) {
        let animation = CABasicAnimation.hideLayerAnimation(at: beginTime)

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
        
        if duration <= 0 {
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
        
        if duration <= 0 {
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
        
        if duration <= 0 {
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
        
        if duration <= 0 {
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
        
        if duration <= 0 {
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
        
        if duration <= 0 {
            animation.speed = 10
        }
        
        animation.fillMode = kCAFillModeForwards
        animation.isRemovedOnCompletion = false
        
        self.addWithKeyname(animation: animation)
    }
}

// MARK: CALayer Helpers
extension CALayer {
    func addWithKeyname(animation: CABasicAnimation) {
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
