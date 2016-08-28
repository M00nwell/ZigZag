//
//  GameViewController.swift
//  ZigZag
//
//  Created by Wenzhe on 18/6/16.
//  Copyright (c) 2016 Wenzhe. All rights reserved.
//

import UIKit
import QuartzCore
import SceneKit

struct bodyNames {
    static let Person = 0x1 << 1
    static let Coin = 0x1 << 2
}

class GameViewController: UIViewController, SCNSceneRendererDelegate, SCNPhysicsContactDelegate {

    let scene = SCNScene()
    let cameraNode = SCNNode()
    
    var person = SCNNode()
    var moveLeft = Bool()
    var firstOne = Bool()
    var dead = Bool()
    
    let firstBox = SCNNode()
    var tempBox = SCNNode()
    var boxNumber = Int()
    var prevBoxNumber = Int()
    
    var score = Int()
    var highScore = Int()
    
    var scoreLabel = UILabel()
    var highscoreLabel = UILabel()
    
    var gameButton = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        createScene()
        scene.physicsWorld.contactDelegate = self
        
        
        scoreLabel = UILabel(frame: CGRect(origin: CGPoint(x: self.view.frame.width / 2, y: self.view.frame.height / 2 + self.view.frame.height / 2.5), size: CGSizeMake(self.view.frame.width, 100)))
        
        scoreLabel.center = CGPoint(x: self.view.frame.width / 2, y: self.view.frame.height / 2 - self.view.frame.height / 2.5)
        scoreLabel.textAlignment = .Center
        scoreLabel.text = "Score : \(score)"
        scoreLabel.textColor = UIColor.darkGrayColor()
        self.view.addSubview(scoreLabel)
        
        highscoreLabel = UILabel(frame: CGRect(origin: CGPoint(x: self.view.frame.width / 2, y: self.view.frame.height / 2 + self.view.frame.height / 2.5), size: CGSizeMake(self.view.frame.width, 100)))
        
        highscoreLabel.center = CGPoint(x: self.view.frame.width / 2, y: self.view.frame.height / 2 + self.view.frame.height / 2.5)
        highscoreLabel.textAlignment = .Center
        highscoreLabel.text = "Highscore : \(highScore)"
        highscoreLabel.textColor = UIColor.darkGrayColor()
        self.view.addSubview(highscoreLabel)
        
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        if dead{
            return
        }
        self.performSelectorOnMainThread(#selector(GameViewController.updateLabel), withObject: nil, waitUntilDone: false)
        if moveLeft == false{
            person.removeAllActions()
            person.runAction(SCNAction.repeatActionForever(SCNAction.moveBy(SCNVector3Make(-70, 0, 0), duration: 20)))
            moveLeft = true
        }else{
            person.removeAllActions()
            person.runAction(SCNAction.repeatActionForever(SCNAction.moveBy(SCNVector3Make(0, 0, -70), duration: 20)))
            moveLeft = false
        }
    }
    
    func physicsWorld(world: SCNPhysicsWorld, didBeginContact contact: SCNPhysicsContact) {
        
        let NodeA = contact.nodeA
        let NodeB = contact.nodeB
        
        if NodeA.physicsBody?.categoryBitMask == bodyNames.Coin
            && NodeB.physicsBody?.categoryBitMask == bodyNames.Person {
            
            NodeA.removeFromParentNode()
            addScore()
            
        }else if NodeB.physicsBody?.categoryBitMask == bodyNames.Coin
            && NodeA.physicsBody?.categoryBitMask == bodyNames.Person{
            
            NodeB.removeFromParentNode()
            addScore()
        }
    }
    
    func renderer(renderer: SCNSceneRenderer, updateAtTime time: NSTimeInterval) {
        
        if dead {
            return
        }
        
        let deleteBox = scene.rootNode.childNodeWithName("\(prevBoxNumber)", recursively: true)
        let currentBox = scene.rootNode.childNodeWithName("\(prevBoxNumber + 1)", recursively: true)
        
        if deleteBox?.position.x > person.position.x + 1 || deleteBox?.position.z > person.position.z + 1 {
            
            prevBoxNumber += 1
            
            fadeOut(deleteBox!)
            //deleteBox?.removeFromParentNode()
            
            createBox()
        }
        
        if (person.position.x > (currentBox?.position.x)! - 0.5 && person.position.x < (currentBox?.position.x)! + 0.5)
            || (person.position.z > (currentBox?.position.z)! - 0.5 && person.position.z < (currentBox?.position.z)! + 0.5){
            
            // on platform
            
        }else{
            
            die()
            dead = true
        }
    }
    
    func die(){
        person.runAction(SCNAction.moveTo(SCNVector3Make(person.position.x, person.position.y - 10, person.position.z), duration: 1.0))
        
        let wait = SCNAction.waitForDuration(0.5)
        let sequence = SCNAction.sequence([wait, SCNAction.runBlock({
            node in
            
            self.scene.rootNode.enumerateChildNodesUsingBlock({
                node, stop in
                
                node.removeFromParentNode()
            })
        }), SCNAction.runBlock({
            node in
            
            self.createScene()
        })])
        
        person.runAction(sequence)
    }
    
    func createCoin(box: SCNNode){
        scene.physicsWorld.gravity = SCNVector3Make(0, 0, 0)
        
        let randomNumber = arc4random() % 8
        
        if randomNumber == 3 {
            let spin = SCNAction.rotateByAngle(CGFloat(M_PI * 2), aroundAxis: SCNVector3Make(0, 1, 0), duration: 0.5)
            let coinScene = SCNScene(named: "Coin.dae")
            let coin = coinScene?.rootNode.childNodeWithName("Coin", recursively: true)
            coin?.position = SCNVector3Make(box.position.x, box.position.y + 1, box.position.z)
            coin?.scale = SCNVector3Make(0.2, 0.2, 0.2)
            
            coin?.physicsBody = SCNPhysicsBody(type: SCNPhysicsBodyType.Dynamic, shape: SCNPhysicsShape(node: coin!, options: nil))
            coin?.physicsBody?.categoryBitMask = bodyNames.Coin
            coin?.physicsBody?.contactTestBitMask = bodyNames.Person
            coin?.physicsBody?.collisionBitMask = bodyNames.Person
            coin?.physicsBody?.affectedByGravity = false
            
            scene.rootNode.addChildNode(coin!)
            coin?.runAction(SCNAction.repeatActionForever(spin))
            fadeIn(coin!)
        }
    }
    
    func createBox() {
        tempBox = SCNNode(geometry: firstBox.geometry)
        let prevBox = scene.rootNode.childNodeWithName("\(boxNumber)", recursively: true)
        
        boxNumber += 1
        
        tempBox.name = "\(boxNumber)"
        
        switch arc4random() % 2 {
        case 0:
            tempBox.position = SCNVector3Make((prevBox?.position.x)! - firstBox.scale.x, (prevBox?.position.y)!, (prevBox?.position.z)! )
            
            if firstOne {
                firstOne = false
                moveLeft = false
            }
            break
        case 1:
            tempBox.position = SCNVector3Make((prevBox?.position.x)!, (prevBox?.position.y)!, (prevBox?.position.z)! - firstBox.scale.z)
            if firstOne {
                firstOne = false
                moveLeft = true
            }
            break
        default:
            break
        }
        
        fadeIn(tempBox)
        scene.rootNode.addChildNode(tempBox)
        createCoin(tempBox)
    }
    
    func fadeIn(node: SCNNode){
        node.opacity = 0
        node.runAction(SCNAction.fadeInWithDuration(0.5))
    }
    
    func fadeOut(node: SCNNode){
        node.runAction(SCNAction.moveTo(SCNVector3Make(node.position.x, node.position.y - 2, node.position.z), duration: 0.5))
        node.runAction(SCNAction.fadeOutWithDuration(0.5))
    }
    
    func createScene() {
        
        let scoreDefault = NSUserDefaults.standardUserDefaults()
        if scoreDefault.integerForKey("highScore") != 0 {
            highScore = scoreDefault.integerForKey("highScore")
        }else{
            highScore = 0
        }
        
        boxNumber = 0
        prevBoxNumber = 0
        score = 0
        firstOne = true
        dead = false
        
        view.backgroundColor = UIColor.whiteColor()
        
        let sceneView = self.view as! SCNView
        sceneView.delegate = self
        sceneView.scene = scene
        
        // create person
        let personGeo = SCNSphere(radius: 0.2)
        person = SCNNode(geometry: personGeo)
        let personMat = SCNMaterial()
        personMat.diffuse.contents = UIColor.redColor()
        personGeo.materials = [personMat]
        person.position = SCNVector3Make(0, 1.1, 0)
        
        person.physicsBody = SCNPhysicsBody(type: SCNPhysicsBodyType.Dynamic, shape: SCNPhysicsShape(node: person, options: nil))
        person.physicsBody?.categoryBitMask = bodyNames.Person
        person.physicsBody?.contactTestBitMask = bodyNames.Coin
        person.physicsBody?.collisionBitMask = bodyNames.Coin
        person.physicsBody?.affectedByGravity = false
        
        scene.rootNode.addChildNode(person)
        
        
        // create camera
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.usesOrthographicProjection = true
        cameraNode.camera?.orthographicScale = 3
        cameraNode.position = SCNVector3Make(20, 20, 20)
        cameraNode.eulerAngles = SCNVector3Make(-45, 45, 0)
        let constraint = SCNLookAtConstraint(target: person)
        constraint.gimbalLockEnabled = true
        cameraNode.constraints = [constraint]
        scene.rootNode.addChildNode(cameraNode)
        
        // create box
        let firstBoxGeo = SCNBox(width: 1, height: 1.5, length: 1, chamferRadius: 0)
        firstBox.geometry = firstBoxGeo
        let boxMaterial = SCNMaterial()
        boxMaterial.diffuse.contents = UIColor(red: 0.2, green: 0.5, blue: 0.5, alpha: 1)
        firstBoxGeo.materials = [boxMaterial]
        firstBox.position = SCNVector3Make(0, 0, 0)
        firstBox.name = "\(boxNumber)"
        firstBox.opacity = 1
        scene.rootNode.addChildNode(firstBox)
        
        for _ in 0...6 {
            createBox()
        }
        
        // create light
        let light = SCNNode()
        light.light = SCNLight()
        light.light?.type = SCNLightTypeDirectional
        light.eulerAngles = SCNVector3Make(-45, 45, 0)
        scene.rootNode.addChildNode(light)
        
        let light2 = SCNNode()
        light2.light = SCNLight()
        light2.light?.type = SCNLightTypeDirectional
        light2.eulerAngles = SCNVector3Make(45, 45, 0)
        scene.rootNode.addChildNode(light2)
        
    }
    
    func addScore(){
        
        score += 1
        self.performSelectorOnMainThread(#selector(GameViewController.updateLabel), withObject: nil, waitUntilDone: false)
        
        if score > highScore {
            highScore = score
            let scoreDefault = NSUserDefaults.standardUserDefaults()
            scoreDefault.setInteger(highScore, forKey: "highScore")
        }
    }
    
    func updateLabel(){
        scoreLabel.text = "Score : \(score)"
        highscoreLabel.text = "Highscore : \(highScore)"
    }
}
