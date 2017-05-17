//
//  BoardView.swift
//  gobang
//
//  Created by Leif on 15/12/2016.
//  Copyright © 2016 Leif. All rights reserved.
//

import Cocoa

protocol Delegate:class{
    func alert(_ boardView: BoardView, msg: String)
    func moved(_ boardView: BoardView, state: CellState)
    func vsMoved(_ boardView: BoardView)
}

class BoardView: NSView {
    var board = Board()
    var n: Int = 15
    var gameOver: Bool = false
    var drawNumber: Bool = false
    var enableAI: Bool = false
    var depth: Int = 3
    var algorithm: Int = 1
    weak var delegate: Delegate?
    
    /***********以下变量用于统计*************/
    var needsOutputCut: Bool = false
    var needsOutputStar: Bool = false
    
    init(frameRect: NSRect, n: Int) {
        super.init(frame: frameRect)
        self.n = n
        board = Board(n: n)
        gameOver = false
        drawNumber = false
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        board.draw(dirtyRect, drawNumber: drawNumber)
    }
    
    func changeOutputCut(needsOutputCut: Bool) {
        self.needsOutputCut = needsOutputCut
    }
    
    func changeVersusAI(versusAI: Bool, depth: Int, algorithm: Int) {
        enableAI = versusAI
        self.depth = depth
        self.algorithm = algorithm
        if !gameOver {
            AIMove(state: CellState.white)
        }
    }
    
    func AIMove(state: CellState){
        if enableAI && board.nowState == state {
            var move: Move
            
            if algorithm == 0 {
                move = board.minMaxAlgorithmNoAB(depth: self.depth)
            } else {
                move = board.minMaxAlgorithmWithAB(depth: self.depth)
            }
            
            if needsOutputCut {
                if algorithm == 0 {
                    board.minMaxAlgorithmWithAB(depth: self.depth)
                } else {
                    board.minMaxAlgorithmNoAB(depth: self.depth)
                }
                
                var string: String
                string = "第" + String(board.nowIndex) + "步："
                Swift.print(string)
                
                string = "访问时间    剪枝前：" + board.noABTime.format(f: ".2") + "ms"
                string += "    剪枝后：" + board.withABTime.format(f: ".2") + "ms"
                Swift.print(string)
                
                string = "访问总节点数目    剪枝前：" + String(board.nodeNoABCount)
                string += "    剪枝后：" + String(board.nodeWithABCount)
                string += "    AB发生次数：" + String(board.ABCut)
                Swift.print(string)
                
                for i in 0...depth {
                    string = "第" + String(i) + "层节点数目    剪枝前：" + String(board.floorCountNoAB[depth - i])
                    string += "    剪枝后：" + String(board.floorCountWithAB[depth - i])
                    Swift.print(string)
                }
                
                Swift.print()
            }
            
            makeMove(row: move.row, col: move.col)
            
            gameOver = board.isGameOver(row: move.row, col: move.col)
            if gameOver {
                delegate?.alert(self, msg: board.nowState == .black ? "白棋胜" : "黑棋胜")
            }
        }
    }
    
    func AIVersusMove(){
        let blackDepth: Int = 3, whiteDepth: Int = 3
        var move: Move
        
        if board.nowState == .black {
            move = board.minMaxAlgorithmWithAB(depth: blackDepth)
        } else {
            move = board.minMaxAlgorithmWithAB(depth: whiteDepth)
        }
        
        makeMove(row: move.row, col: move.col)
        
        gameOver = board.isGameOver(row: move.row, col: move.col)
        if gameOver {
            delegate?.alert(self, msg: board.nowState == .black ? "白棋胜" : "黑棋胜")
        } else {
            delegate?.vsMoved(self)
        }
    }
    
    func clearBoard(){
        board = Board(n: n)
        gameOver = false
        
        setNeedsDisplay(self.frame)
    }
    
    func withdraw() -> Bool{
        let flag: Bool = board.withdraw()
        if flag {
            gameOver = false
            setNeedsDisplay(self.frame)
        }
        return flag
    }
    
    func makeMove(row: Int, col: Int){
        board.makeMove(row: row, col: col)
        setNeedsDisplay(self.frame)
        delegate?.moved(self, state: board.nowState)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.0))     // 用于强制刷新UI
    }
    
    override func mouseDown(with event: NSEvent) {
        if gameOver || ( enableAI && board.nowState == .white ) { return }
        
        let mouseLocation: NSPoint = NSEvent.mouseLocation()
        let windowLocation: NSPoint = NSPoint(x: self.window!.frame.minX, y: self.window!.frame.minY)
        let imageViewLocation: NSPoint = NSPoint(x: self.superview!.frame.minX, y: self.superview!.frame.minY)
        
//        Swift.print(mouseLocation)
//        Swift.print(windowLocation)
//        Swift.print(imageViewLocation)
        
        let baseWidth: CGFloat = (self.frame.maxX - self.frame.minX) / CGFloat(n), baseHeight: CGFloat = (self.frame.maxY - self.frame.minY) / CGFloat(n)
        let drawRect = self.frame.insetBy(dx: baseWidth / 2, dy: baseHeight / 2)
        
        let boardWidth: CGFloat = drawRect.maxX - drawRect.minX, boardHeight: CGFloat = drawRect.maxY - drawRect.minY
        let offsetWidth: CGFloat = boardWidth / CGFloat(n - 1), offsetHeight: CGFloat = boardHeight / CGFloat(n - 1)
        
        let locationInBoardView: NSPoint = NSPoint(x: mouseLocation.x - windowLocation.x - imageViewLocation.x, y: mouseLocation.y - windowLocation.y - imageViewLocation.y)
        let row: Int = Int((locationInBoardView.x - baseWidth / 2 + offsetWidth / 2) / offsetWidth) + 1, col: Int = Int ((locationInBoardView.y - baseHeight / 2 + offsetHeight / 2) / offsetHeight) + 1
        
        if board.board[row][col] == .space {
            makeMove(row: row, col: col)
            
            gameOver = board.isGameOver(row: row, col: col)
            if gameOver {
                delegate?.alert(self, msg: board.nowState == .black ? "白棋胜" : "黑棋胜")
            } else {
                AIMove(state: board.nowState)
                
                if !needsOutputCut && enableAI && board.nowState != .white{
                    var string: String
                    string = "第" + String(board.nowIndex - 1) + "步："
                    Swift.print(string)
                    
                    if algorithm == 0 {
                        string = "访问时间：" + board.noABTime.format(f: ".2") + "ms"
                    } else {
                        string = "访问时间：" + board.withABTime.format(f: ".2") + "ms"
                    }
                    Swift.print(string)
                    
                    if algorithm == 0 {
                        string = "访问总节点数目：" + String(board.nodeNoABCount)
                    } else {
                        string = "访问总节点数目：" + String(board.nodeWithABCount)
                    }
                    Swift.print(string)
                    
                    for i in 0...depth {
                        if algorithm == 0 {
                            string = "第" + String(i) + "层节点数目：" + String(board.floorCountNoAB[depth - i])
                        } else {
                            string = "第" + String(i) + "层节点数目：" + String(board.floorCountWithAB[depth - i])
                        }
                        Swift.print(string)
                    }
                    Swift.print()
                }
            }
        }
    }
}
