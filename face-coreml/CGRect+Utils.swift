//
//  CGRect+Utils.swift
//  face-coreml
//
//  Created by Daniel Otero Cortes on 28/2/18.
//  Copyright © 2018 Daniel Otero Cortes. All rights reserved.
//

import UIKit

extension CGRect {
    static func *(left: CGRect, right: CGSize) -> CGRect {
        let width = right.width
        let height = right.height
        return CGRect(x: left.origin.x * width, y: left.origin.y * height, width: left.size.width * width, height: left.size.height * height)
    }
    
    func toUIKitRect(totalHeight: CGFloat = 1) -> CGRect {
        return CGRect(x: self.origin.x, y: totalHeight - self.origin.y - self.size.height, width: self.size.width, height: self.size.height)
    }
    
    static func boundingBox(points: [CGPoint]) -> CGRect? {
        guard points.count > 2 else {
            return nil
        }
        var minX = points[0].x
        var maxX = points[0].x
        var minY = points[0].y
        var maxY = points[0].y
        points.forEach { point in
            minX = min(minX,point.x)
            maxX = max(maxX,point.x)
            minY = min(minY,point.y)
            maxY = max(maxY,point.y)
        }
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
}
