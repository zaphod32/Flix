//
//  GameScene.swift
//  Flix
//
//  Created by Nicholas on 12/3/15.
//  Copyright (c) 2015 Nicholas Ritchie. All rights reserved.
//

import SpriteKit
//import ProjectileSprite

struct PhysicsCategory {
    static let None      : UInt32 = 0
    static let All       : UInt32 = UInt32.max
    static let Monster   : UInt32 = 0b1       // 1
    static let Projectile: UInt32 = 0b10      // 2
    static let Wall: UInt32 = 0b100
}

func + (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

func - (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

func * (point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x * scalar, y: point.y * scalar)
}

func / (point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x / scalar, y: point.y / scalar)
}

#if !(arch(x86_64) || arch(arm64))
    func sqrt(a: CGFloat) -> CGFloat {
        return CGFloat(sqrtf(Float(a)))
    }
#endif

extension CGPoint {
    func length() -> CGFloat {
        return sqrt(x*x + y*y)
    }
    
    func normalized() -> CGPoint {
        return self / length()
    }
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    let player = SKSpriteNode(imageNamed: "player")
    var pegs = [Peg]()
    var selectedPeg: Peg? = nil
    var indicator = SKSpriteNode(imageNamed: "player")
    let indicatorMaxDist = 30
    
    override func didMoveToView(view: SKView) {
    
        let peg1 = Peg()
        pegs.append(peg1)
        
        for peg in pegs{
            addChild(peg.sprite)
        }
        
        indicator.hidden = true
        addChild(indicator)
        
        
//        let backgroundMusic = SKAudioNode(fileNamed: "background-music-aac.caf")
//        backgroundMusic.autoplayLooped = true
//        addChild(backgroundMusic)
        
        physicsWorld.gravity = CGVectorMake(0, 0)
        physicsWorld.contactDelegate = self
        self.physicsBody = SKPhysicsBody.init(edgeLoopFromRect: self.frame)
        self.physicsBody?.categoryBitMask = PhysicsCategory.Wall

        
        backgroundColor = SKColor.whiteColor()
        player.position = CGPoint(x: size.width * 0.1, y: size.height * 0.5)
        addChild(player)
        
        runAction(SKAction.repeatActionForever(
            SKAction.sequence([
                SKAction.runBlock(addMonster),
                SKAction.waitForDuration(1.0)
                ])
            ))
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
       /* Called when a touch begins */
        guard let touch = touches.first else {
            return
        }
        let touchLocation = touch.locationInNode(self)
        
        for peg in pegs{
            if peg.contains(touchLocation){
                peg.selected = true
                selectedPeg = peg
                print ("selected")
            }
        }

    }
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if (selectedPeg == nil) {
            return
        }
        
        print("move")
        guard let touch = touches.first else {
            return
        }
        let touchLocation = touch.locationInNode(self)
        
        let distanceVector = touchLocation - selectedPeg!.location
        let distance = distanceVector.length()
        if distance < CGFloat(indicatorMaxDist){
            indicator.position = touchLocation
        }else{
            indicator.position = (touchLocation - selectedPeg!.location).normalized()*30 + selectedPeg!.location
        }
        
        indicator.hidden = false
    }
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        indicator.hidden = true
        
        // 1 - Choose one of the touches to work with
        guard let touch = touches.first else {
            return
        }
        let touchLocation = touch.locationInNode(self)
        
        // 2 - Set up initial location of projectile
        let projectile = ProjectileSprite(imageNamed: "projectile")
        projectile.position = player.position
        if (selectedPeg != nil) {
            projectile.position = selectedPeg!.sprite.position
        }else{
            selectedPeg = nil
            return
        }
        selectedPeg = nil
        
        // 3 - Determine offset of location to projectile
        let offset = touchLocation - projectile.position
        
        // 4 - Bail out if you are shooting down or backwards
//        if (offset.x < 0) { return }
        
        // 5 - OK to add now - you've double checked position
        projectile.physicsBody = SKPhysicsBody(circleOfRadius: projectile.size.width/2)
        projectile.physicsBody?.dynamic = true
        projectile.physicsBody?.categoryBitMask = PhysicsCategory.Projectile
        projectile.physicsBody?.contactTestBitMask = PhysicsCategory.Monster | PhysicsCategory.Wall
        projectile.physicsBody?.collisionBitMask = PhysicsCategory.None
        projectile.physicsBody?.usesPreciseCollisionDetection = true
       
        projectile.origen = projectile.position
        
        addChild(projectile)
        
        // 6 - Get the direction of where to shoot
        let direction = offset.normalized()
        
        // 7 - Make it shoot far enough to be guaranteed off screen
        let shootAmount = direction * -1000
        
        // 8 - Add the shoot amount to the current position
        let realDest = shootAmount + projectile.position
        
        // 9 - Create the actions
        let actionMove = SKAction.moveTo(realDest, duration: 2.0)
        let actionMoveDone = SKAction.removeFromParent()
        projectile.runAction(SKAction.sequence([actionMove, actionMoveDone]))
        
//        runAction(SKAction.playSoundFileNamed("pew-pew-lei.caf", waitForCompletion: false))
    }
//   
//    override func update(currentTime: CFTimeInterval) {
//        /* Called before each frame is rendered */
//    }
    func didBeginContact(contact: SKPhysicsContact) {
        
        // 1
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
            
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        print(firstBody.categoryBitMask)
        print(secondBody.categoryBitMask)
        // if shuriken hits monster
        if ((firstBody.categoryBitMask & PhysicsCategory.Monster != 0) &&
            (secondBody.categoryBitMask & PhysicsCategory.Projectile != 0)) {
                projectileDidCollideWithMonster(firstBody.node as! SKSpriteNode, monster: secondBody.node as! SKSpriteNode)
        }
//       if projectile hits wall
        if ((firstBody.categoryBitMask & PhysicsCategory.Projectile != 0) &&
            (secondBody.categoryBitMask & PhysicsCategory.Wall != 0)){
//                create wall(pegLocation, contactLocation)
                let projectile = firstBody.node as! ProjectileSprite
                let contactPoint = contact.contactPoint
                let startingPoint = projectile.origen
                createWall(contactPoint, point2: startingPoint)
                projectile.removeFromParent()
        }
        
    }
    func createWall(point1: CGPoint, point2: CGPoint){
        print("hit wall")
        var path = CGPathCreateMutable()
        CGPathMoveToPoint(path, nil, point1.x, point1.y)
        CGPathAddLineToPoint(path, nil, point2.x, point2.y)
        
        let shapeNode = SKShapeNode()
        shapeNode.path = path
        shapeNode.name = "line"
        shapeNode.strokeColor = UIColor.grayColor()
        shapeNode.lineWidth = 2
        shapeNode.zPosition = 1
        
        self.addChild(shapeNode)
        var test = 0
        
    }
    func projectileDidCollideWithMonster(projectile:SKSpriteNode, monster:SKSpriteNode) {
        print("Hit")
        projectile.removeFromParent()
        monster.removeFromParent()
        
        
    }
    
    func random() -> CGFloat {
        return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
    }
    
    func random(min min: CGFloat, max: CGFloat) -> CGFloat {
        return random() * (max - min) + min
    }
    
    func addMonster() {
        
        // Create sprite
        let monster = SKSpriteNode(imageNamed: "monster")
        monster.physicsBody = SKPhysicsBody(rectangleOfSize: monster.size) // 1
        monster.physicsBody?.dynamic = true // 2
        monster.physicsBody?.categoryBitMask = PhysicsCategory.Monster // 3
        monster.physicsBody?.contactTestBitMask = PhysicsCategory.Projectile // 4
        monster.physicsBody?.collisionBitMask = PhysicsCategory.None // 5
        
        // Determine where to spawn the monster along the Y axis
        let actualY = random(min: monster.size.height/2, max: size.height - monster.size.height/2)
        
        // Position the monster slightly off-screen along the right edge,
        // and along a random position along the Y axis as calculated above
        monster.position = CGPoint(x: size.width + monster.size.width/2, y: actualY)
        
        // Add the monster to the scene
        addChild(monster)
        
        // Determine speed of the monster
        let actualDuration = random(min: CGFloat(2.0), max: CGFloat(4.0))
        
        // Create the actions
        let actionMove = SKAction.moveTo(CGPoint(x: -monster.size.width/2, y: actualY), duration: NSTimeInterval(actualDuration))
        let actionMoveDone = SKAction.removeFromParent()
        monster.runAction(SKAction.sequence([actionMove, actionMoveDone]))
        
    }
}
