//
//  UIImageExtensions.swift
//  koala-tea-video-editor
//
//  Created by Craig Holliday on 1/14/18.
//  Copyright © 2018 Koala Tea. All rights reserved.
//

import UIKit

extension UIImage {
    func putImage(image: UIImage, on rect: CGRect, angle: CGFloat = 0.0) -> UIImage {

        let drawRect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        UIGraphicsBeginImageContextWithOptions(drawRect.size, false, 1.0)

        // Start drawing self
        self.draw(in: drawRect)

        // Drawing new image on top
        let context = UIGraphicsGetCurrentContext()!

        // Get the center of new image
        // Changed this to origin, for some reason that makes it work
        let center = CGPoint(x: rect.origin.x, y: rect.origin.y)

        // Set center of image as context action point, so rotation works right
        context.translateBy(x: center.x, y: center.y)
        context.saveGState()

        // Rotate the context
        context.rotate(by: angle)

        // Context origin is image's center. So should draw image on point on origin
        image.draw(in: CGRect(origin: CGPoint(x: -rect.size.width/2, y: -rect.size.height/2), size: rect.size), blendMode: .normal, alpha:
            1.0)

        // Go back to context original state.
        context.restoreGState()

        // Get new image
        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()

        return newImage
    }
}
