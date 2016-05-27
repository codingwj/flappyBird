//
//  GameViewController.swift
//  flappyBird
//
//  Created by wangju on 16/5/16.
//  Copyright (c) 2016年 wangju. All rights reserved.
//

import UIKit
import SpriteKit

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        setUpScene()
  
    }
    
    func setUpScene() -> GameScene? {
        if let scene = GameScene(fileNamed:"GameScene") {
            // Configure the view.
            let skView = self.view as! SKView
            skView.showsFPS = true
            skView.showsNodeCount = true
            
            /* Sprite Kit applies additional optimizations to improve rendering performance */
            skView.ignoresSiblingOrder = true
            
            /* Set the scale mode to scale to fit the window */
            scene.scaleMode = .AspectFill
            
            skView.presentScene(scene)
            
            scene.gameWillReset =
                
            {
                    print("-----")
                    self.setUpScene()
            }
            return scene
        }
        return nil

    }

    override func shouldAutorotate() -> Bool {
        return true
    }

    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            return .AllButUpsideDown
        } else {
            return .All
        }
    }
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}
