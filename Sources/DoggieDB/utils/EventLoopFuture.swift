//
//  EventLoopFuture.swift
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

extension Dictionary {
    
    func flatten<_Value>(
        on eventLoop: EventLoop
    ) -> EventLoopFuture<[Key: _Value]> where Value == EventLoopFuture<_Value> {
        return eventLoop.flatten(self)
    }
}

extension EventLoop {
    
    func flatten<Key: Hashable, Value>(
        _ futures: [Key: EventLoopFuture<Value>]
    ) -> EventLoopFuture<[Key: Value]> {
        return EventLoopFuture<Value>.whenAllSucceed(futures, on: self)
    }
}

extension EventLoopFuture {
    
    static func whenAllSucceed<Key: Hashable>(
        _ futures: [Key: EventLoopFuture<Value>],
        on eventLoop: EventLoop
    ) -> EventLoopFuture<[Key: Value]> {
        let promise = eventLoop.makePromise(of: [Key: Value].self)
        EventLoopFuture.whenAllSucceed(futures, promise: promise)
        return promise.futureResult
    }
    
    static func whenAllSucceed<Key: Hashable>(
        _ futures: [Key: EventLoopFuture<Value>],
        promise: EventLoopPromise<[Key: Value]>
    ) {
        
        let eventLoop = promise.futureResult.eventLoop
        let reduced = eventLoop.makePromise(of: Void.self)
        
        var results: [Key: Value] = .init(minimumCapacity: futures.count)
        
        if eventLoop.inEventLoop {
            self._reduceSuccesses(reduced, futures, eventLoop) { results[$0] = $1 }
        } else {
            eventLoop.execute {
                self._reduceSuccesses(reduced, futures, eventLoop) { results[$0] = $1 }
            }
        }
        
        reduced.futureResult.whenComplete { result in
            switch result {
            case .success: promise.succeed(results)
            case .failure(let error): promise.fail(error)
            }
        }
    }
    
    private static func _reduceSuccesses<Key: Hashable, InputValue>(
        _ promise: EventLoopPromise<Void>,
        _ futures: [Key: EventLoopFuture<InputValue>],
        _ eventLoop: EventLoop,
        onValue: @escaping (Key, InputValue) -> Void
    ) {
        
        eventLoop.assertInEventLoop()
        
        var remainingCount = futures.count
        
        if remainingCount == 0 {
            promise.succeed(())
            return
        }
        
        for (key, future) in futures {
            
            future.hop(to: eventLoop).whenComplete { result in
                
                switch result {
                case let .success(result):
                    
                    onValue(key, result)
                    remainingCount -= 1
                    
                    if remainingCount == 0 {
                        promise.succeed(())
                    }
                    
                case let .failure(error): promise.fail(error)
                }
            }
        }
    }
}
