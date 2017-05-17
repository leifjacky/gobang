//
//  Board.swift
//  gobang
//
//  Created by Leif on 15/12/2016.
//  Copyright © 2016 Leif. All rights reserved.
//

import Cocoa

let boardColor: NSColor = NSColor(calibratedRed: 40.0 / 255, green: 28.0 / 255, blue: 9.0 / 255, alpha: 1)

// 扩展Double，使它可以直接控制输出精度，用于显示耗时
extension Double{
    func format(f: String) -> String{
        return NSString(format: "%\(f)f" as NSString, self) as String
    }
}

enum CellState{
    case space, black, white
}

class Move{
    var row: Int, col: Int, state: CellState
    
    init(){
        row = 0
        col = 0
        state = .space
    }
    
    init(row: Int, col: Int, state: CellState){
        self.row = row
        self.col = col
        self.state = state
    }
}

class Board{
    let LSCORE: Dictionary<Int, Int> = [5:1000000, 4: 55000, 3: 5500, 2: 1000, 1: 50]
    let DSCORE: Dictionary<Int, Int> = [5:1000000, 4: 30000, 3: 2000, 2: 100 , 1: 1]
    
    var n: Int
    var board: [[CellState]]
    var index: [[Int]]
    var nowState: CellState
    var nowIndex: Int
    var offsetWidth: CGFloat, offsetHeight: CGFloat
    var moves: Stack
    
    /********以下变量用于统计*********/
    var nodeNoABCount: Int = 0,nodeWithABCount: Int = 0
    var ABCut: Int = 0
    var noABTime: Double = 0, withABTime: Double = 0
    var floorCountNoAB: [Int] = [Int](), floorCountWithAB: [Int] = [Int]()
    /********以上变量用于统计*********/
    
    init(){
        n = 15
        board = [[CellState]](repeating: [CellState](repeating: .space, count: n + 1), count: n + 1)
        index = [[Int]](repeating: [Int](repeating: 0, count: n + 1), count: n + 1)
        nowState = .black
        nowIndex = 1
        offsetWidth = 1
        offsetHeight = 1
        moves = Stack()
    }
    
    init(n: Int) {
        self.n = n
        board = [[CellState]](repeating: [CellState](repeating: .space, count: n + 1), count: n + 1)
        index = [[Int]](repeating: [Int](repeating: 0, count: n + 1), count: n + 1)
        nowState = .black
        nowIndex = 1
        offsetWidth = 1
        offsetHeight = 1
        moves = Stack()
    }
    
    func makeMove(row: Int, col: Int){
        moves.push(object: Move(row: row, col: col, state: nowState) as AnyObject)
        board[row][col] = nowState
        index[row][col] = nowIndex
        nowState = nowState == .black ? .white : .black
        nowIndex += 1
    }
    
    func withdraw() -> Bool {
        if moves.size() < 2 {
            return false
        }
        
        var move: Move
        move = moves.pop() as! Move
        board[move.row][move.col] = .space
        move = moves.pop() as! Move
        board[move.row][move.col] = .space
        
        nowIndex -= 2
        
        return true
    }
    
    func check(row: Int, col: Int) -> Bool {
        return row > 0 && row <= n && col > 0 && col <= n
    }
    
    func isGameOver(row: Int, col: Int) -> Bool{
        let vx: [Int] = [1, 1, 1, 0]
        let vy: [Int] = [1, 0, -1, -1]
        
        for i in 0 ..< 4 {
            var count: Int = 1
            var currentRow: Int = row + vx[i], currentCol: Int = col + vy[i]
            while check(row: currentRow, col: currentCol) && board[currentRow][currentCol] == board[row][col] {
                count += 1
                currentRow += vx[i]
                currentCol += vy[i]
            }
            
            currentRow = row - vx[i]; currentCol = col - vy[i]
            while check(row: currentRow, col: currentCol) && board[currentRow][currentCol] == board[row][col] {
                count += 1
                currentRow -= vx[i]
                currentCol -= vy[i]
            }
            
            if count >= 5 { return true }
        }
        
        return false
    }
    
    func skyEye(_ rect: NSRect){
        let circlePath = NSBezierPath(ovalIn: rect)
        boardColor.setFill()
        circlePath.fill()
    }
    
    func draw(_ rect: NSRect, drawNumber: Bool){
        let baseWidth: CGFloat = (rect.maxX - rect.minX) / CGFloat(n), baseHeight: CGFloat = (rect.maxY - rect.minY) / CGFloat(n)
        let drawRect = rect.insetBy(dx: baseWidth / 2, dy: baseHeight / 2)
//        print(rect)
//        print(drawRect)
        
        let boardWidth: CGFloat = drawRect.maxX - drawRect.minX, boardHeight: CGFloat = drawRect.maxY - drawRect.minY
        offsetWidth = boardWidth / CGFloat(n - 1)
        offsetHeight = boardHeight / CGFloat(n - 1)
        
        let line = NSBezierPath()
        for i in 0 ..< n {
            line.move(to: NSPoint(x: drawRect.minX + CGFloat(i) * offsetWidth, y: drawRect.minY))
            line.line(to: NSPoint(x: drawRect.minX + CGFloat(i) * offsetWidth, y: drawRect.maxY))
            line.move(to: NSPoint(x: drawRect.minX, y: drawRect.minY + CGFloat(i) * offsetHeight))
            line.line(to: NSPoint(x: drawRect.maxX, y: drawRect.minY + CGFloat(i) * offsetHeight))
        }
        line.lineWidth = 1
        boardColor.setStroke()
        line.stroke()
        
        let frameRect = rect.insetBy(dx: 5, dy: 5)
        let frameLine = NSBezierPath()
        frameLine.move(to: NSPoint(x: frameRect.minX, y: frameRect.minY))
        frameLine.line(to: NSPoint(x: frameRect.minX, y: frameRect.maxY))
        frameLine.line(to: NSPoint(x: frameRect.maxX, y: frameRect.maxY))
        frameLine.line(to: NSPoint(x: frameRect.maxX, y: frameRect.minY))
        frameLine.close()
        frameLine.lineWidth = 2
        boardColor.setStroke()
        frameLine.stroke()
        
        if n > 10 && n & 1 == 1{
            let midN: Int = n / 2
            let skyEyeSize: CGFloat = offsetWidth / 5
            skyEye(NSRect(x: drawRect.minX + CGFloat(midN) * offsetWidth - skyEyeSize / 2, y: drawRect.minY + CGFloat(midN) * offsetHeight - skyEyeSize / 2, width: skyEyeSize, height: skyEyeSize))
            skyEye(NSRect(x: drawRect.minX + CGFloat(midN - 4) * offsetWidth - skyEyeSize / 2, y: drawRect.minY + CGFloat(midN - 4) * offsetHeight - skyEyeSize / 2, width: skyEyeSize, height: skyEyeSize))
            skyEye(NSRect(x: drawRect.minX + CGFloat(midN - 4) * offsetWidth - skyEyeSize / 2, y: drawRect.minY + CGFloat(midN + 4) * offsetHeight - skyEyeSize / 2, width: skyEyeSize, height: skyEyeSize))
            skyEye(NSRect(x: drawRect.minX + CGFloat(midN + 4) * offsetWidth - skyEyeSize / 2, y: drawRect.minY + CGFloat(midN - 4) * offsetHeight - skyEyeSize / 2, width: skyEyeSize, height: skyEyeSize))
            skyEye(NSRect(x: drawRect.minX + CGFloat(midN + 4) * offsetWidth - skyEyeSize / 2, y: drawRect.minY + CGFloat(midN + 4) * offsetHeight - skyEyeSize / 2, width: skyEyeSize, height: skyEyeSize))
        }
        
        for row in 1 ... n{
            for col in 1 ... n{
                if board[row][col] != CellState.space{
                    let circleRect = NSRect(x: drawRect.minX + CGFloat(row - 1) * offsetWidth - offsetWidth / 2, y: drawRect.minY + CGFloat(col - 1) * offsetHeight - offsetHeight / 2, width: offsetWidth, height: offsetHeight)
                    let circlePath = NSBezierPath(ovalIn: circleRect)
                    (board[row][col] == .black ? NSColor.black : NSColor.white).setFill()
                    circlePath.fill()
                    
                    if drawNumber {
                        let str: NSString = NSString(string: String(index[row][col]))
                        let paragraphStyle: NSMutableParagraphStyle = NSMutableParagraphStyle()
                        paragraphStyle.alignment = NSTextAlignment.center
                        let font: NSFont = NSFont(name: (NSText().font?.fontName)!, size: {() -> CGFloat in
                            if index[row][col] < 10 {
                                return max(1, offsetWidth - 5)
                            } else if index[row][col] < 100{
                                return max(1, offsetWidth - 13)
                            } else {
                                return max(1, offsetWidth - 20)
                            }}())!
                        let attributes: NSDictionary = [
                            NSFontAttributeName: font,
                            NSParagraphStyleAttributeName: paragraphStyle,
                            NSForegroundColorAttributeName: board[row][col] == .black ? NSColor.white : NSColor.black ]
                        str.draw(in: circleRect, withAttributes: attributes as! [String : Any])
                    }
                }
            }
        }
    }
 
    func evalate() -> Int {
        var blackScore: Int = 0, whiteScore: Int = 0
        
        // 行向量、列向量
        for i in 1...n{
            var row: [CellState] = [CellState]()
            var col: [CellState] = [CellState]()
            for j in 1...n{
                row.append(board[i][j])
                col.append(board[j][i])
            }
            blackScore += calScore(cellVector: row, state: CellState.black)
            blackScore += calScore(cellVector: col, state: CellState.black)
            
            whiteScore += calScore(cellVector: row, state: CellState.white)
            whiteScore += calScore(cellVector: col, state: CellState.white)
        }
        
        // 正对角线
        for i in 1...n{
            var cells: [CellState] = [CellState]()
            var row: Int = i, col: Int = 1
            while row <= n && col <= n {
                cells.append(board[row][col])
                row += 1
                col += 1
            }
            blackScore += calScore(cellVector: cells, state: CellState.black)
            whiteScore += calScore(cellVector: cells, state: CellState.white)
        }
        
        for i in 2...n{
            var cells: [CellState] = [CellState]()
            var row: Int = 1, col: Int = i
            while row <= n && col <= n {
                cells.append(board[row][col])
                row += 1
                col += 1
            }
            blackScore += calScore(cellVector: cells, state: CellState.black)
            whiteScore += calScore(cellVector: cells, state: CellState.white)
        }
        
        // 反对角线
        for i in 1...n {
            var cells: [CellState] = [CellState]()
            var row: Int = n, col: Int = i
            while row > 0 && col <= n {
                cells.append(board[row][col])
                row -= 1
                col += 1
            }
            blackScore += calScore(cellVector: cells, state: CellState.black)
            whiteScore += calScore(cellVector: cells, state: CellState.white)
        }
        
        for i in 1..<n {
            var cells: [CellState] = [CellState]()
            var row: Int = i, col: Int = 1
            while row > 0 && col <= n {
                cells.append(board[row][col])
                row -= 1
                col += 1
            }
            blackScore += calScore(cellVector: cells, state: CellState.black)
            whiteScore += calScore(cellVector: cells, state: CellState.white)
        }
        
        if nowState == .white {
            return whiteScore - blackScore
        } else {
            return blackScore - whiteScore
        }
    }
    
    func calScore(cellVector: [CellState], state: CellState) -> Int{
        if cellVector.count <= 0 { return 0 }
        var score: Int = 0
        var count: Int = 0, emptyTail: Int = 0
        
        for cellState in cellVector {
            if cellState == state {
                count += 1
            } else if cellState == .space {
                score += getScore(count: count, emptyTail: emptyTail)
                emptyTail = 1
                count = 0
            } else {
                score += getScore(count: count, emptyTail: emptyTail)
                emptyTail = 0
                count = 0
            }
        }
        
        score += getScore(count: count, emptyTail: emptyTail)
        return score
    }
    
    func getScore(count: Int, emptyTail: Int) -> Int {
        if count >= 5 {
            return LSCORE[5]!
        } else if count == 4 {
            if emptyTail == 2 {
                return LSCORE[4]!
            } else if emptyTail == 1{
                return DSCORE[4]!
            }
        } else if count == 3 {
            if emptyTail == 2 {
                return LSCORE[3]!
            } else if emptyTail == 1 {
                return DSCORE[3]!
            }
        } else if count == 2 {
            if emptyTail == 2 {
                return LSCORE[2]!
            } else if emptyTail == 1 {
                return DSCORE[2]!
            }
        } else if count == 1 {
            if emptyTail == 2 {
                return LSCORE[1]!
            } else if emptyTail == 1 {
                return DSCORE[1]!
            }
        }
        return 0
    }
    
    func moveScore(row: Int, col: Int) -> Int{
        let vx: [Int] = [1, 1, 1, 0]
        let vy: [Int] = [1, 0, -1, -1]
        var score: Int = 0
        
        for i in 0 ..< 4 {
            var count: Int = 1, emptyTail: Int = 0
            var currentRow: Int = row + vx[i], currentCol: Int = col + vy[i]
            while check(row: currentRow, col: currentCol) {
                if board[currentRow][currentCol] == board[row][col] {
                    count += 1
                } else {
                    if board[currentRow][currentCol] == .space {
                        emptyTail += 1
                    }
                    break
                }
                
                currentRow += vx[i]
                currentCol += vy[i]
            }
            
            currentRow = row - vx[i]; currentCol = col - vy[i]
            while check(row: currentRow, col: currentCol) {
                if board[currentRow][currentCol] == board[row][col] {
                    count += 1
                } else {
                    if board[currentRow][currentCol] == .space {
                        emptyTail += 1
                    }
                    break
                }
                
                currentRow -= vx[i]
                currentCol -= vy[i]
            }
            
            score += getScore(count: count, emptyTail: emptyTail)
        }
        
        return score
    }
    
    func hasNeighbour(row: Int, col: Int, vx: Int, vy: Int) -> Bool {
        if board[row][col] != .space { return false }
        for i in max(1, row - vx)...min(n, row + vx){
            for j in max(1, col - vy)...min(n, col + vy){
                if board[i][j] != .space { return true }
            }
        }
        return false
    }
    
    func generatePossiblePointsOld(state: CellState, depth: Int) -> [Move]{
        var neighbourPoints: [Move] = [Move]()
        var nextToNeighbourPoints: [Move] = [Move]()
        
        for row in 1...n{
            for col in 1...n{
                let move: Move = Move(row: row, col: col, state: state)
                if hasNeighbour(row: row, col: col, vx: 1, vy: 1){
                    neighbourPoints.append(move)
                } else if depth > 1 && hasNeighbour(row: row, col: col, vx: 2, vy: 2){
                    nextToNeighbourPoints.append(move)
                }
            }
        }
        
        return neighbourPoints + nextToNeighbourPoints
    }
    
    func generatePossiblePoints(state: CellState, depth: Int) -> [Move]{
        let opState: CellState = state == .black ? .white : .black
        
        var neighbourPoints: [Move] = [Move]()
        var nextToNeighbourPoints: [Move] = [Move]()
        
        var fives: [Move] = [Move]()
        var fours: [Move] = [Move]()
        var twothrees: [Move] = [Move]()
        var threes: [Move] = [Move]()
        var twos: [Move] = [Move]()
        
        for row in 1...n{
            for col in 1...n{
                let move: Move = Move(row: row, col: col, state: state)
                if hasNeighbour(row: row, col: col, vx: 1, vy: 1){
                    board[row][col] = state
                    let score: Int = moveScore(row: row, col: col)
                    board[row][col] = opState
                    let opScore: Int = moveScore(row: row, col: col)
                    board[row][col] = .space
                    
                    if score >= LSCORE[5]! {
                        return [Move](repeating: move, count: 1)
                    } else if opScore >= LSCORE[5]! {
                        fives.append(move)
                    } else if score >= LSCORE[4]! {
                        fours.insert(move, at: fours.startIndex)
                    } else if opScore >= LSCORE[4]! {
                        fours.append(move)
                    } else if score >= LSCORE[3]! * 2 {
                        twothrees.insert(move, at: twothrees.startIndex)
                    } else if opScore >= LSCORE[3]! * 2 {
                        twothrees.append(move)
                    } else if score >= LSCORE[3]! {
                        threes.insert(move, at: threes.startIndex)
                    } else if opScore >= LSCORE[3]! {
                        threes.append(move)
                    } else if score >= LSCORE[2]! {
                        twos.insert(move, at: twos.startIndex)
                    } else if opScore >= LSCORE[2]! {
                        twos.append(move)
                    } else {
                        neighbourPoints.append(move)
                    }
                } else if depth > 1 && hasNeighbour(row: row, col: col, vx: 2, vy: 2){
                    nextToNeighbourPoints.append(move)
                }
            }
        }
        
        if fives.count > 0 { return fives }
        if fours.count > 0 { return fours }
        if twothrees.count > 0 { return twothrees }
        
        return threes + twos + neighbourPoints + nextToNeighbourPoints
    }
    
    /*********以下代码没有剪枝*********/
    func minMaxAlgorithmNoAB(depth: Int) -> Move{
        nodeNoABCount = 1
        floorCountNoAB = [Int](repeating: 0, count: n + 1)
        floorCountNoAB[depth] += 1
        
        let startDate = CFAbsoluteTimeGetCurrent()
        
        var best: Int = Int.min
        var bestPoints: [Move] = [Move]()
        let possiblePoints: [Move] = generatePossiblePoints(state: nowState, depth: depth)
        
        for point in possiblePoints{
            board[point.row][point.col] = point.state
            let mark = minNoAB(lastPoint: point, depth: depth - 1)
            if mark == best {
                bestPoints.append(point)
            } else if mark > best {
                best = mark
                bestPoints.removeAll()
                bestPoints.append(point)
            }
            board[point.row][point.col] = .space
        }
        
        let endDate = CFAbsoluteTimeGetCurrent()
        noABTime = Double(endDate-startDate) * Double(1000)
        
        return bestPoints[Int(arc4random()) % bestPoints.count]
    }
    
    func minNoAB(lastPoint: Move, depth: Int) -> Int{
        nodeNoABCount += 1
        floorCountNoAB[depth] += 1
        
        if depth <= 0 || isGameOver(row: lastPoint.row, col: lastPoint.col) {
            return evalate()
        }
        
        var best: Int = Int.max
        let possiblePoints: [Move] = generatePossiblePoints(state: lastPoint.state == .black ? .white : .black, depth: depth)
        
        for point in possiblePoints{
            board[point.row][point.col] = point.state
            let mark = maxNoAB(lastPoint: point, depth: depth - 1)
            if mark < best {
                best = mark
            }
            board[point.row][point.col] = .space
        }
        
        return best
    }
    
    func maxNoAB(lastPoint: Move, depth: Int) -> Int{
        nodeNoABCount += 1
        floorCountNoAB[depth] += 1
        
        if depth <= 0 || isGameOver(row: lastPoint.row, col: lastPoint.col) {
            return evalate()
        }
        
        var best: Int = Int.min
        let possiblePoints: [Move] = generatePossiblePoints(state: lastPoint.state == .black ? .white : .black, depth: depth)
        
        for point in possiblePoints{
            board[point.row][point.col] = point.state
            let mark = minNoAB(lastPoint: point, depth: depth - 1)
            if mark > best {
                best = mark
            }
            board[point.row][point.col] = .space
        }
        
        return best
    }
    /*********以上代码没有剪枝*********/
    
    /*********以下代码包含剪枝*********/
    /*********alpha极小值点的下界，beta为极大值点的上界***********/
    
    func minMaxAlgorithmWithAB(depth: Int) -> Move {
        nodeWithABCount = 1
        ABCut = 0
        floorCountWithAB = [Int](repeating: 0, count: n + 1)
        floorCountWithAB[depth] += 1
        
        let startDate = CFAbsoluteTimeGetCurrent()
        
        var best: Int = Int.min
        var bestPoints: [Move] = [Move]()
        let possiblePoints: [Move] = generatePossiblePoints(state: nowState, depth: depth)
        
        for point in possiblePoints{
            board[point.row][point.col] = point.state
            let mark = minWithAB(lastPoint: point, depth: depth - 1, alpha: max(best, Int.min), beta: Int.max)
            if mark == best {
                bestPoints.append(point)
            } else if mark > best {
                best = mark
                bestPoints.removeAll()
                bestPoints.append(point)
            }
            board[point.row][point.col] = .space
        }
        
        let endDate = CFAbsoluteTimeGetCurrent()
        withABTime = Double(endDate-startDate) * Double(1000)
        
        return bestPoints[Int(arc4random()) % bestPoints.count]
    }
    
    func minWithAB(lastPoint: Move, depth: Int, alpha: Int, beta: Int) -> Int{
        nodeWithABCount += 1
        floorCountWithAB[depth] += 1
        
        if depth <= 0 || isGameOver(row: lastPoint.row, col: lastPoint.col) {
            return evalate()
        }
        
        var best: Int = Int.max
        let possiblePoints: [Move] = generatePossiblePoints(state: lastPoint.state == .black ? .white : .black, depth: depth)
        
        for point in possiblePoints{
            board[point.row][point.col] = point.state
            let mark: Int = maxWithAB(lastPoint: point, depth: depth - 1, alpha: alpha, beta: min(best, beta))
            if mark < best {
                best = mark
            }
            board[point.row][point.col] = .space
            if mark < alpha {
                ABCut += 1
                break
            }
        }
        
        return best
    }
    
    func maxWithAB(lastPoint: Move, depth: Int, alpha: Int, beta: Int) -> Int{
        nodeWithABCount += 1
        floorCountWithAB[depth] += 1
        
        if depth <= 0 || isGameOver(row: lastPoint.row, col: lastPoint.col) {
            return evalate()
        }
        
        var best: Int = Int.min
        let possiblePoints: [Move] = generatePossiblePoints(state: lastPoint.state == .black ? .white : .black, depth: depth)
        
        for point in possiblePoints{
            board[point.row][point.col] = point.state
            let mark = minWithAB(lastPoint: point, depth: depth - 1, alpha: max(best, alpha), beta: beta)
            if mark > best {
                best = mark
            }
            board[point.row][point.col] = .space
            if mark > beta {
                ABCut += 1
                break
            }
        }
        
        return best
    }

    /*********以上代码包含剪枝*********/
}
