//
//  Peg.swift
//  Flix
//
//  Created by Nicholas on 12/3/15.
//  Copyright © 2015 Nicholas Ritchie. All rights reserved.
//

import UIKit
import SpriteKit

class Peg: NSObject {
    var selected = false
    var location = CGPoint(x: 100, y: 100)
    let radius = 10.0
    var sprite = SKSpriteNode(imageNamed: "projectile")
    
    override init() {
        sprite = SKSpriteNode(imageNamed: "projectile")
        location = CGPoint(x: 100, y: 100)
        sprite.position = location
        
       
    }

    func contains(point: CGPoint) -> Bool{
        let distanceX =  point.x - location.x
        let distanceY =  point.y - location.y
        let distance =  sqrt(distanceX*distanceX + distanceY*distanceY)
        return Double(distance) < radius
    }
}
