//
//  GameScene.swift
//  flappyBird
//
//  Created by wangju on 16/5/16.
//  Copyright (c) 2016年 wangju. All rights reserved.
//

import SpriteKit


class GameScene: SKScene {
    
    // GameScene 中
    var canRestart = false
    var verticalPipeGap : Int
    {
        get
        {
            return Int(arc4random_uniform(50) + 150);
        }
    }
    
    let pipeCateGory:UInt32 = 1
    let birdCateGory:UInt32 = 2
    let worldCateGory:UInt32 = 4
    let scoreCateGory:UInt32 = 8
    
    let eachActionTime:CGFloat = 0.008
    
    
    /** 向上的管道 */
    lazy var pipeTextureUp:SKTexture = {
        let pipeTextureUp = SKTexture(imageNamed: "pipe_up")
        pipeTextureUp.filteringMode = .Nearest
        return pipeTextureUp
    }()
    /** 创建向下的管道 */
    var pipeTextureDown:SKTexture = {
        let pipeTextureDown = SKTexture(imageNamed: "pipe_down")
        pipeTextureDown.filteringMode = .Nearest
        return pipeTextureDown
    }()

    lazy var bird:SKSpriteNode = {
        // 初始化小鸟
        let birdTexture1 = SKTexture(imageNamed: "bird0_0")
        birdTexture1.filteringMode = .Nearest
        let birdTexture2 = SKTexture(imageNamed: "bird0_1")
        birdTexture2.filteringMode = .Nearest
        let birdTexture3 = SKTexture(imageNamed: "bird0_2")
        birdTexture3.filteringMode = .Nearest
        
        let anim = SKAction.animateWithTextures([birdTexture1,birdTexture2,birdTexture3], timePerFrame: 0.2)
        let flap = SKAction.repeatActionForever(anim)
        
        let bird = SKSpriteNode(texture: birdTexture1)
        bird.physicsBody?.dynamic = true
        bird.position = CGPoint(x: self.frame.size.width * 0.5, y: self.frame.size.height * 0.6)
        bird.runAction(flap)
        
        bird.physicsBody = SKPhysicsBody(circleOfRadius: (bird.size.height) / 2.0)
        bird.physicsBody?.dynamic = true
        bird.physicsBody?.allowsRotation = false
        
        return bird
    }()
    
    lazy var scoreLabelNode : SKLabelNode = {

        weak var weakself = self
        let scoreLabelNode = SKLabelNode(fontNamed: "MarkerFelt-Wide")
        scoreLabelNode.position = CGPointMake(CGRectGetMidX(weakself!.frame), weakself!.frame.size.height * 3 / 4)
        scoreLabelNode.zPosition = 100
        scoreLabelNode.text = String(self.score)
        return scoreLabelNode
    
    }()
    
    var pipes:SKNode?
    
    var movePipesAndRemove:SKAction?
    
    var touchFlag = false
    
    var moving : SKNode? = nil
    
    var score = 0
    
    var gameOverLabelNode:SKLabelNode?
    
    var gameWillReset : (()->Void) = {}
    
    
 
    override func didMoveToView(view: SKView) {
        /* Setup your scene here */
        // 游戏初始化
        gameInit()
    }
    
    func gameInit() {
        
        canRestart = false
        
        // 初始化物理引擎
        
        physicsWorld.gravity = CGVectorMake(0.0, -5.0)
        physicsWorld.contactDelegate = self
        
        // 设置背景颜色
        let skyColor = SKColor(colorLiteralRed: 81.0 / 255, green: 192.0 / 255, blue: 201.0 / 255, alpha: 1.0)
        backgroundColor = skyColor
        
        // 用于移动的节点
        moving = SKNode()
        addChild(moving!)
        
        // 管道节点
        pipes = SKNode()
        moving!.addChild(pipes!)
        
        // 地面
        let groundTexture = SKTexture(imageNamed: "land")
        //Each pixel is drawn using the nearest point in the texture. This mode is faster, but the results are often pixelated.
        groundTexture.filteringMode = .Nearest
        
        // 移动地面动作
        
        let landSpeed = groundTexture.size().width * 2.0
        
        let moveGroundSprite = SKAction.moveBy(CGVectorMake(-landSpeed, 0), duration: NSTimeInterval(eachActionTime * landSpeed))
        // 重置地面动作
        let resetGroundSprite = SKAction.moveBy(CGVectorMake(landSpeed, 0), duration: NSTimeInterval(0))
        // 无线移动地面的动作
        let moveGroundSpriteForever = SKAction.repeatActionForever(SKAction.sequence([moveGroundSprite,resetGroundSprite]))
        
        for i in 0.0.stride(to: (Double)(2.0 + self.frame.size.width / landSpeed), by: 1.0) {
            let sprite = SKSpriteNode(texture: groundTexture)
            sprite.setScale(2.0)
            let spriteX = (CGFloat)(i) * sprite.size.width
            
            sprite.position = CGPointMake(spriteX, sprite.size.height / 2.0)
            sprite.runAction(moveGroundSpriteForever)
            moving!.addChild(sprite)
        }
        
        // 创建管道操作
        let distanceToMove = CGFloat(self.frame.size.width + pipeTextureUp.size().width)
        let movePipes = SKAction.moveByX(-distanceToMove, y: 0.0, duration: NSTimeInterval(eachActionTime * distanceToMove))
        let removePipes = SKAction.removeFromParent()
        
        movePipesAndRemove = SKAction.sequence([movePipes,removePipes])
        
        // 开始产生大量的管道
        weak var weekSelf = self
        let spawn = SKAction.runBlock { 
            () in weekSelf!.spwanPipes()
        }
        let delay = SKAction.waitForDuration(NSTimeInterval(1.5))
        let spawnThenDelay = SKAction.sequence([spawn,delay])
        let spawnThenDelayForever = SKAction.repeatActionForever(spawnThenDelay)
        self.runAction(spawnThenDelayForever)
        
        // 初始化小鸟
        bird.physicsBody?.categoryBitMask = birdCateGory
        bird.physicsBody?.collisionBitMask = worldCateGory | pipeCateGory
        bird.physicsBody?.contactTestBitMask = worldCateGory | pipeCateGory
        addChild(bird)
        
        // 创建地面
        let ground = SKNode()
        ground.position = CGPointMake(0, groundTexture.size().height)
        ground.physicsBody = SKPhysicsBody(rectangleOfSize: CGSizeMake(frame.size.width, groundTexture.size().height * 2.0))
        ground.physicsBody?.dynamic = false
        ground.physicsBody?.categoryBitMask = worldCateGory
        addChild(ground)
        
        // 初始化计分的标签对象
        score = 0
        addChild(scoreLabelNode)
        
        // 初始化gameOver的标签对象
        gameOverLabelNode = SKLabelNode(fontNamed: "MarkerFelt-Wide")
        gameOverLabelNode!.position = CGPointMake(CGRectGetMidX(frame), 3 * frame.size.height / 4 - 60)
        gameOverLabelNode!.fontSize = 60
        gameOverLabelNode!.text = "Game Over"
        gameOverLabelNode!.hidden = true
        gameOverLabelNode!.fontColor = SKColor(red: 1, green: 0, blue: 0, alpha: 1.0)
        addChild(gameOverLabelNode!)
    
    }
    
    func spwanPipes() {

        // 该节点用于显示上下两个管道
        let pipePair = SKNode()
        pipePair.position = CGPointMake(self.frame.size.width + pipeTextureUp.size().width, 0)
        pipePair.zPosition = -10
        
        let height = (UInt32(self.frame.size.height.native) / 4)
        let y = arc4random() % height + height
        
        // 创建下管道
        let pipeDown = SKSpriteNode(texture: pipeTextureDown)
        pipeDown.setScale(1.0)
        pipeDown.position = CGPointMake(0.0, CGFloat(UInt(y)) + pipeDown.size.height + CGFloat(verticalPipeGap))
        
        // 设置下管道的物理引擎属性，以便用物理引擎检测碰撞
        pipeDown.physicsBody = SKPhysicsBody(rectangleOfSize: pipeDown.size)
        pipeDown.physicsBody?.dynamic = false
        pipeDown.physicsBody?.categoryBitMask = pipeCateGory
        pipeDown.physicsBody?.contactTestBitMask = birdCateGory
        pipePair.addChild(pipeDown)
        
        // 创建上管道
        let pipeUp = SKSpriteNode(texture: pipeTextureUp)
        pipeUp.setScale(1.0)
        pipeUp.position = CGPointMake(0.0, CGFloat(UInt(y)))
        
        // 设置上管道的物理引擎
        pipeUp.physicsBody = SKPhysicsBody(rectangleOfSize: pipeUp.size)
        pipeUp.physicsBody?.dynamic = false
        pipeUp.physicsBody?.categoryBitMask = pipeCateGory
        pipeUp.physicsBody?.contactTestBitMask = birdCateGory
        pipePair.addChild(pipeUp)
        
        // 该节点什么都不实现，用于检测碰撞
        let contactNode = SKNode()
        contactNode.position = CGPointMake(pipeDown.size.width + (bird.size.width) / 2, CGRectGetMidY(frame))
        contactNode.physicsBody = SKPhysicsBody(rectangleOfSize: CGSizeMake(pipeUp.size.width, self.frame.size.height))
        contactNode.physicsBody?.dynamic = false
        contactNode.physicsBody?.categoryBitMask = scoreCateGory
        contactNode.physicsBody?.contactTestBitMask = birdCateGory
        
        
        
        pipePair.addChild(contactNode)
        // 让管道不断移动，若移除屏幕则删除
        pipePair.runAction(movePipesAndRemove!)
        pipes?.addChild(pipePair)
   
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
       /* Called when a touch begins */
        touchFlag = true
        
        if moving?.speed > 0 {
            for _ : AnyObject in touches {
                bird.physicsBody?.velocity = CGVectorMake(0, 0)
                // 牛顿力，弹起小鸟
                bird.physicsBody?.applyImpulse(CGVectorMake(0, 30))
            }
        }else if canRestart
        {
            //重置场景
            resetScene()
        }

    }
    
    func didBeginContact(contact: SKPhysicsContact) {
        if moving?.speed > 0 {
            if (contact.bodyA.categoryBitMask & scoreCateGory) == scoreCateGory || (contact.bodyB.categoryBitMask & scoreCateGory) == scoreCateGory {
                score += 1
                scoreLabelNode.text = String(score)
                // 将当前分数显示到label上
                scoreLabelNode.runAction(SKAction.sequence([SKAction.scaleTo(1.5, duration: NSTimeInterval(0.1)),SKAction.scaleTo(1.0, duration: NSTimeInterval(0.1))]))
            
            }
            else
            {
                moving?.speed = 0
                bird.physicsBody?.collisionBitMask = worldCateGory
                bird.runAction(SKAction.rotateByAngle(CGFloat(M_PI) * (bird.position.y) * 0.01, duration: 1), completion: {
                    self.bird.speed = 0
                })
                
                let showLabelAction : SKAction = SKAction.runBlock({ 
                    if self.touchFlag
                    {
                        self.gameOverLabelNode?.hidden = false
                    }
                })
                    // 显示gameOver
                    
                let redColorAction : SKAction = SKAction.runBlock({
                        self.gameOverLabelNode?.fontColor = SKColor(red: 1, green: 0, blue: 0, alpha: 1.0)
                })
                
                let whiteColorAction : SKAction = SKAction.runBlock({
                    self.gameOverLabelNode?.fontColor = SKColor(red: 1, green: 1, blue: 1, alpha: 1.0)
                })
                
                let canRestartAction = SKAction.runBlock({ 
                    self.canRestart = true
                })
                
                
                let waitAction = SKAction.waitForDuration(NSTimeInterval(0.1))
                
                let actions = [showLabelAction,redColorAction,waitAction,whiteColorAction,waitAction]
                    
                let repeatAction = SKAction.repeatAction(SKAction.sequence(actions), count: 4)
                runAction(SKAction.sequence([repeatAction,canRestartAction]))
       
            }
   
        }
    }
   
    func resetScene() {
        gameWillReset()

    }
    
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
    }
}

extension GameScene : SKPhysicsContactDelegate
{


}
