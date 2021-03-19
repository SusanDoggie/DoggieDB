//
//  extension.swift
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

extension HTTPClient.Body {
    
    public init(_ stream: Request.Body, maxSize: Int = Int.max, eventLoop: EventLoop) {
        
        self = .stream { writer in
            
            var size = 0
            
            let promise = eventLoop.makePromise(of: Void.self)
            
            stream.drain { stream in
                
                switch stream {
                
                case let .buffer(buffer):
                    
                    size += buffer.readableBytes
                    
                    if size > maxSize {
                        let error = Abort(.payloadTooLarge)
                        promise.fail(error)
                        return eventLoop.makeFailedFuture(error)
                    }
                    
                case .end:
                    
                    promise.succeed(())
                    
                case let .error(error):
                    
                    promise.fail(error)
                }
                
                return eventLoop.makeSucceededVoidFuture()
            }
            
            return promise.futureResult
        }
    }
}
