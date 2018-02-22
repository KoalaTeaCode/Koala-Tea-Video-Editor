//
//  CoreLayerManager.swift
//  koala-tea-video-editor
//
//  Created by Craig Holliday on 1/11/18.
//  Copyright © 2018 Koala Tea. All rights reserved.
//

import Foundation
import UIKit

enum CALayerGeometryKeyPaths {
    case opacity
    case backgroundColor
    case position
    case positionX
    case positionY
    case positionZ
    case scale
    case scaleX
    case scaleY
    case scaleZ
    case rotate
    case rotateX
    case rotateY
    case rotateZ
    
    var key: String {
        switch self {
        case .opacity:
            return #keyPath(CALayer.opacity)
        case .backgroundColor:
            return #keyPath(CALayer.backgroundColor)
        case .position:
            return #keyPath(CALayer.position)
        case .positionX:
            return #keyPath(CALayer.position) + ".x"
        case .positionY:
            return #keyPath(CALayer.position) + ".y"
        case .positionZ:
            return #keyPath(CALayer.position) + ".z"
        case .scale:
            return #keyPath(CALayer.transform) + ".scale"
        case .scaleX:
            return #keyPath(CALayer.transform) + ".scale" + ".x"
        case .scaleY:
            return #keyPath(CALayer.transform) + ".scale" + ".y"
        case .scaleZ:
            return #keyPath(CALayer.transform) + ".scale" + ".z"
        case .rotate:
            return #keyPath(CALayer.transform) + ".rotate"
        case .rotateX:
            return #keyPath(CALayer.transform) + ".rotate" + ".x"
        case .rotateY:
            return #keyPath(CALayer.transform) + ".rotate" + ".y"
        case .rotateZ:
            return #keyPath(CALayer.transform) + ".rotate" + ".z"
        }
        //@TODO: Rotate
    }
}

// @TODO: Make enum for things like kCAGravityCenter, kCAFillModeForwards, and kCAAlignmentCenter

public class CoreLayerManager {
    public class func createTextLayer(frame: CGRect,
                                      text: String,
                                      textColor: UIColor = .black,
                                      font: UIFont = UIFont.systemFont(ofSize: 20)) -> CATextLayer {
        let textLayer = CATextLayer()
        
        // CALayer Properties
        textLayer.name = text
        textLayer.frame = frame
        textLayer.contentsGravity = kCAGravityCenter
        textLayer.shouldRasterize = true
        textLayer.contentsScale = 2.0
        textLayer.rasterizationScale = 2.0
        //@TODO: Check what is the best magnification filter
        textLayer.magnificationFilter = kCAFilterTrilinear
        textLayer.needsDisplayOnBoundsChange = true
        textLayer.fillMode = kCAFillModeForwards
        
        //@TODO: ADD THESE IN
        textLayer.borderWidth = 0
        textLayer.borderColor = UIColor.clear.cgColor
        textLayer.shadowOffset = CGSize(width: 0, height: 0)
//        textLayer.backgroundColor = UIColor.lightGray.cgColor
//        textLayer.cornerRadius = 8
        
        // CATextLayer Specific
        textLayer.string = text
        textLayer.foregroundColor = textColor.cgColor
        textLayer.font = font
        textLayer.fontSize = font.pointSize
        textLayer.isWrapped = true
        textLayer.alignmentMode = kCAAlignmentCenter
        
        // Should we adjust height?
//        textLayer.adjustHeightToFit()
        
        textLayer.display()
        
        return textLayer
    }
}

extension CALayer {
    public func setAnchorPoint(anchorPoint: CGPoint) {
        let newPoint = CGPoint(x: self.bounds.size.width * anchorPoint.x, y: self.bounds.size.height * anchorPoint.y)
        let oldPoint = CGPoint(x: self.bounds.size.width * self.anchorPoint.x, y: self.bounds.size.height * self.anchorPoint.y)
        
        var position = self.position
        position.x -= oldPoint.x
        position.x += newPoint.x
        
        position.y -= oldPoint.y
        position.y += newPoint.y
        
        self.position = position
        self.anchorPoint = anchorPoint
    }
}

//@TODO: Find out how this may fit into workflow
//mostly if this breaks setting the frame on init

// MARK: Size To Fit Text
// Have to set this before display()
extension CATextLayer {
    private func getTextAdjustedSize() -> CGSize? {
        guard let string = self.string else {
            return nil
        }

        guard !(string is NSAttributedString) else {
            let outString = self.string as! NSAttributedString
            return outString.size()
        }
        
        var outfont: UIFont = UIFont.systemFont(ofSize: fontSize)
        let layerfont: CFTypeRef = self.font!

        // If we have string instead of UIFont
        if (layerfont) is String {
            if let newFont = UIFont(name: (layerfont as? String) ?? "", size: fontSize) {
                outfont = newFont
            }
        } else {
            let fontTypeid: CFTypeID = CFGetTypeID(layerfont)
            if fontTypeid == CTFontGetTypeID() {
                let fontName: CFString = CTFontCopyPostScriptName(layerfont as! CTFont)
                if let newFont = UIFont(name: (fontName as String), size: fontSize) {
                    outfont = newFont
                }
            }
        }
        
        let outString = NSAttributedString(string: string as! String, attributes: [NSAttributedStringKey.font : outfont])
        return outString.size()
    }
    
    func sizeToFit() {
        guard let newSize = self.getTextAdjustedSize() else {
            assertionFailure("No new size was given")
            return
        }
        self.frame.size = newSize
    }
    
    public func adjustHeightToFit() {
        guard let newSize = self.getTextAdjustedSize() else {
            assertionFailure("No new size was given")
            return
        }

        self.frame.size.height = newSize.height
    }
}
