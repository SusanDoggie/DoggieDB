//
//  DBPair.swift
//
//  The MIT License
//  Copyright (c) 2015 - 2021 Susan Cheng. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

@dynamicMemberLookup
public struct DBPair<Left, Right> {
    
    public var left: Left
    
    public var right: Right
    
}

extension DBPair {
    
    public subscript<Value>(dynamicMember keyPath: KeyPath<Left, Value>) -> Value {
        return self.left[keyPath: keyPath]
    }
    
    public subscript<Value>(dynamicMember keyPath: KeyPath<Right, Value>) -> Value {
        return self.right[keyPath: keyPath]
    }
}

extension DBPair {
    
    public subscript<Value>(dynamicMember keyPath: WritableKeyPath<Left, Value>) -> Value {
        get {
            return self.left[keyPath: keyPath]
        }
        set {
            self.left[keyPath: keyPath] = newValue
        }
    }
    
    public subscript<Value>(dynamicMember keyPath: WritableKeyPath<Right, Value>) -> Value {
        get {
            return self.right[keyPath: keyPath]
        }
        set {
            self.right[keyPath: keyPath] = newValue
        }
    }
}
