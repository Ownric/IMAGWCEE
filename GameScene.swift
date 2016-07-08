//
//  GameScene.swift
//  GameJamTurretGame
//
//  Created by Owen Meyer on 7/5/16.
//  Copyright (c) 2016 Owen Meyer. All rights reserved.
//

import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    enum bulletLifeState {
        case Exists, Doesnt
    }
    
    enum GameSceneState {
        case Active, GameOver
    }
    
    var gameState: GameSceneState = .Active
    
    var lifeState: bulletLifeState = .Doesnt
    
    var hero: SKSpriteNode!
    
    var bulletPosX: CGFloat!
    
    var obstacleLayer: SKNode!
    
    let fixedDelta: CFTimeInterval = 1.0/60.0 /* 60 FPS */
    
    var scrollSpeed: CGFloat = 160.0
    
    var spawnTimer: CFTimeInterval = 0
    
    var sinceTouch : CFTimeInterval = 0
    
    var spawnSpeed: Double = 1.5
    
    var speedTimer: CFTimeInterval = 0
    
    var buttonRestart: MSButtonNode!
    
    var scoreLabel: SKLabelNode!
    
    var points = 0
    
    var gameOver: SKLabelNode!
    
    override func didMoveToView(view: SKView) {
        obstacleLayer = self.childNodeWithName("obstacleLayer")
        physicsWorld.contactDelegate = self
        
        buttonRestart = childNodeWithName("//buttonRestart") as! MSButtonNode
        
        scoreLabel = self.childNodeWithName("scoreLabel") as! SKLabelNode
        
        gameOver = self.childNodeWithName("gameOver") as! SKLabelNode
        
        buttonRestart.selectedHandler = {
            
            /* Grab reference to our SpriteKit view */
            let skView = self.view as SKView!
            
            /* Load Game scene */
            let scene = GameScene(fileNamed:"GameScene") as GameScene!
            
            /* Ensure correct aspect mode */
            scene.scaleMode = .AspectFill
            
            /* Show debug */
            skView.showsPhysics = false
            skView.showsDrawCount = true
            skView.showsFPS = false
            
            /* Restart game scene */
            skView.presentScene(scene)
        }
        
        scoreLabel.text = String(points)
        
        gameOver.text = String(" ")
        
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
       /* Called when a touch begins */
        
        if gameState != .Active { return }
        
        sinceTouch = 0
        
        hero = self.childNodeWithName("//hero") as! SKSpriteNode
        let heroref = self.childNodeWithName("heroReference") as! SKReferenceNode
        
        for touch in touches {
            let location = touch.locationInNode(self)
            
            let resourcePath = NSBundle.mainBundle().pathForResource("heroBullets", ofType: "sks")
            let heroBullet = MSReferenceNode(URL: NSURL (fileURLWithPath: resourcePath!))
            addChild(heroBullet)
            
            heroref.position.y = location.y - 25
            
            heroBullet.avatar.position.y = heroref.position.y + 25
            heroBullet.avatar.position.x = heroref.position.x + 40
            
            heroBullet.avatar.physicsBody?.applyImpulse(CGVectorMake(5, 0))
            
            bulletPosX = heroBullet.avatar.position.x
            lifeState = .Exists
            
        }
    }
   
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
        
        if gameState != .Active { return }
        
        sinceTouch+=fixedDelta
        
        updateObstacles()
        
        spawnTimer+=fixedDelta
        
        speedTimer+=fixedDelta
        if speedTimer % 5 >= 4.9999{
            spawnSpeed -= 0.1
        }
        if speedTimer % 10 >= 9.9999 {
            scrollSpeed += 10.0
        }
    }
    
    func updateObstacles() {
        /* Update Obstacles */
        
        obstacleLayer.position.x = obstacleLayer.position.x - (scrollSpeed * CGFloat(fixedDelta))
        
        /* Loop through obstacle layer nodes */
        for obstacle in obstacleLayer.children as! [SKReferenceNode] {
            
            /* Get obstacle node position, convert node position to scene space */
            let obstaclePosition = obstacleLayer.convertPoint(obstacle.position, toNode: self)
            
            /* Check if obstacle has left the scene */
            if obstaclePosition.x <= -40 {
                print("obstacle named: \(obstacle.parent!.name)")
                gameOver.text = String("Game Over")
                /* Remove obstacle node from obstacle layer */
                obstacle.removeFromParent()
                gameState = .GameOver
            }
            
            
        }
        
        /* Time to add a new obstacle? */
        if spawnTimer >= spawnSpeed {
            
            /* Create a new obstacle reference object using our obstacle resource */
            let resourcePath = NSBundle.mainBundle().pathForResource("EnemyBullet", ofType: "sks")
            let newObstacle = SKReferenceNode (URL: NSURL (fileURLWithPath: resourcePath!))
            obstacleLayer.addChild(newObstacle)
            
            /* Generate new obstacle position, start just outside screen and with a random y value */
            let randomPosition = CGPointMake(352, CGFloat.random(min: 40, max: 528))
            
            /* Convert new node position back to obstacle layer space */
            newObstacle.position = self.convertPoint(randomPosition, toNode: obstacleLayer)
            
            // Reset spawn timer
            spawnTimer = 0
        }
        
    }
    
    func didBeginContact(contact: SKPhysicsContact) {
        /* Get references to bodies involved in collision */
        let contactA:SKPhysicsBody = contact.bodyA
        let contactB:SKPhysicsBody = contact.bodyB
        
        /* Get references to the physics body parent nodes */
        let nodeA = contactA.node!
        let nodeB = contactB.node!
        
        /* Check if either physics bodies was a enemy bullet */
        if contactA.categoryBitMask == 2 || contactB.categoryBitMask == 2 {
                
                /* Kill Seal(s) */
            killBullet(nodeA)
            killBullet(nodeB)
            
            points += 1
            
            /* Update score label */
            scoreLabel.text = String(points)
            
        }
    }
    
    func killBullet(node:SKNode){
        let bulletDeath = SKAction.runBlock({
            node.parent?.parent?.removeFromParent()
        })
        
        self.runAction(bulletDeath)
    }
}
