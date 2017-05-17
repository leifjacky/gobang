//
//  ViewController.swift
//  gobang
//
//  Created by Leif on 15/12/2016.
//  Copyright © 2016 Leif. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, Delegate {
    
    @IBOutlet weak var checkBoxOutputCut: NSButton!
    @IBOutlet weak var popUpSelectAlgorithm: NSPopUpButton!
    @IBOutlet weak var currentChess: NSImageView!
    @IBOutlet weak var textFieldN: NSTextField!
    @IBOutlet weak var imageView: NSImageView!
    @IBOutlet weak var checkBoxDrawNumber: NSButton!
    @IBOutlet weak var checkBoxVersusAI: NSButton!
    @IBOutlet weak var textFieldDepth: NSTextField!
    var boardView = BoardView()
    var currentMove = CurrentMove()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.wantsLayer = true
        
        self.view.addSubview(imageView)
        imageView.addSubview(boardView)
        
        //let answer = dialogOKCancel(question: "Ok?", text: "Choose your answer.")
    }
    
    @IBAction func generateBoardView(_ sender: Any) {
        boardView.removeFromSuperview()
        
        let n = Int(textFieldN.stringValue)!
        boardView = BoardView(frameRect: imageView.bounds, n: n)
        boardView.delegate = self
        boardView.drawNumber = checkBoxDrawNumber.state == 1 ? true : false
        
        imageView.addSubview(boardView)
        imageView.image = #imageLiteral(resourceName: "wood")
        
        currentMove = CurrentMove(frame: currentChess.bounds)
        currentMove.state = .black
        currentChess.addSubview(currentMove)
        
        versusAI(self)
    }
    
    @IBAction func enterN(_ sender: Any) {
        generateBoardView(self)
    }
    @IBAction func clearBoard(_ sender: Any) {
        boardView.clearBoard()
        boardView.drawNumber = checkBoxDrawNumber.state == 1 ? true : false
        currentMove.state = .black
        currentMove.setNeedsDisplay(currentMove.frame)
    }

    @IBAction func withdraw(_ sender: Any) {
        boardView.withdraw()
    }
    
    @IBAction func versusAI(_ sender: Any) {
        boardView.changeVersusAI(versusAI: checkBoxVersusAI.state == 1, depth: Int(textFieldDepth.stringValue)!, algorithm: popUpSelectAlgorithm.indexOfSelectedItem)
    }
    
    @IBAction func checkDrawNumber(_ sender: Any) {
        boardView.drawNumber = checkBoxDrawNumber.state == 1 ? true : false
        boardView.setNeedsDisplay(boardView.frame)
    }
    
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    func alert(_ boardView: BoardView, msg: String){
        dialogOKCancel(question: "Game Over", text: msg)
    }
    
    func moved(_ boardView: BoardView, state: CellState) {
        currentMove.state = state
        currentMove.setNeedsDisplay(currentMove.frame)
    }
    
    func vsMoved(_ boardView: BoardView) {
        boardView.AIVersusMove()
    }
    
    func dialogOKCancel(question: String, text: String) -> Bool {
        let myPopup: NSAlert = NSAlert()
        myPopup.messageText = question
        myPopup.informativeText = text
        myPopup.alertStyle = NSAlertStyle.warning
        return myPopup.runModal() == NSAlertFirstButtonReturn
    }
    
    @IBAction func outuptCut(_ sender: Any) {
        boardView.changeOutputCut(needsOutputCut: checkBoxOutputCut.state == 1)
    }
    
    @IBAction func ComVSCom(_ sender: Any) {
        boardView.makeMove(row: Int((boardView.n + 1) / 2), col: Int((boardView.n + 1) / 2))
        vsMoved(boardView)
    }
    
}

class CurrentMove: NSView {
    var state: CellState = .black
    
    override func draw(_ dirtyRect: NSRect) {
        let circlePath = NSBezierPath(ovalIn: dirtyRect)
        (state == .black ? NSColor.black : NSColor.white).setFill()
        circlePath.fill()
    }
}
