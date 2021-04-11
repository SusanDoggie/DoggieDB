//
//  DBMongoMaxAwaitTimeMSOptions.swift
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

import MongoSwift

public protocol DBMongoMaxAwaitTimeMSOptions {
    
    var maxAwaitTimeMS: Int? { get set }
    
}

extension DBMongoExpression where Options: DBMongoMaxAwaitTimeMSOptions {
    
    /// The maximum amount of time, in milliseconds, for the server to wait on new documents to satisfy a tailable
    /// cursor query. This only applies when used with `MongoCursorType.tailableAwait`. Otherwise, this option is
    /// ignored.
    public func maxAwaitTimeMS(_ maxAwaitTimeMS: Int) -> Self {
        var result = self
        result.options.maxAwaitTimeMS = maxAwaitTimeMS
        return result
    }
    
}
