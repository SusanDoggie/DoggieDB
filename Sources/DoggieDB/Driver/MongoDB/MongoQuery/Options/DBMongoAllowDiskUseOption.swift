//
//  DBMongoAllowDiskUseOption.swift
//
//  The MIT License
//  Copyright (c) 2015 - 2022 Susan Cheng. All rights reserved.
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

public protocol DBMongoAllowDiskUseOption {
    
    var allowDiskUse: Bool? { get set }
    
}

extension DBMongoExpression where Options: DBMongoAllowDiskUseOption {
    
    /// Enables the server to write to temporary files. When set to true, the find operation
    /// can write data to the _tmp subdirectory in the dbPath directory. This helps prevent
    /// out-of-memory failures server side when working with large result sets.
    ///
    /// - Note:
    ///    This option is only supported in MongoDB 4.4+. Specifying it against earlier versions of the server
    ///    will result in an error.
    public func allowDiskUse(_ allowDiskUse: Bool) -> Self {
        var result = self
        result.options.allowDiskUse = allowDiskUse
        return result
    }
    
}

