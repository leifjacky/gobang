//
//  Stack.swift
//  gobang
//
//  Created by Leif on 26/12/2016.
//  Copyright © 2016 Leif. All rights reserved.
//

import Foundation

class Stack{
    var stack: [AnyObject]
    
    init() {
        stack = [AnyObject]()
    }
    
    func size() -> Int{
        return stack.count
    }
    
    func empty() -> Bool{
        return stack.count == 0
    }
    
    func push(object: AnyObject){
        stack.append(object)
    }
    
    func pop() -> AnyObject{
        return stack.removeLast()
    }
    
    func clear() -> Int{
        stack.removeAll()
        return size()
    }
}
