//
//  WebSocketController.swift
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

public class WebSocketController: RouteCollection {
    
    public var logger: Logger
    
    private let encoder = ExtendedJSONEncoder()
    private let decoder = ExtendedJSONDecoder()
    
    public init(logger: Logger) {
        self.logger = logger
    }
    
    public func boot(routes: RoutesBuilder) throws {
        
        routes.webSocket { req, ws in
            
            let session = Session()
            
            ws.onText {
                do {
                    try self.onMessage($0, session, self.decoder.decode(BSON.self, from: $1._utf8_data))
                } catch {
                    self.logger.error("\(error)")
                }
            }
            
            ws.onBinary {
                do {
                    try self.onMessage($0, session, self.decoder.decode(BSON.self, from: $1))
                } catch {
                    self.logger.error("\(error)")
                }
            }
            
            ws.onClose.whenComplete {
                switch $0 {
                case .success: self.onClose(session, nil)
                case let .failure(error): self.onClose(session, error)
                }
            }
        }
    }
}

extension WebSocketController {
    
    private class Session {
        
        var connection: DBConnection?
    }
}

extension WebSocketController {
    
    private func send(_ ws: WebSocket, _ message: BSON) {
        try? ws.send(raw: encoder.encode(message), opcode: .text)
    }
    
    private func sendError(_ ws: WebSocket, _ errorCode: Int64, _ message: String) {
        self.send(ws, ["error": true, "errorCode": .int64(errorCode), "message": .string(message)])
    }
}

extension WebSocketController {
    
    private func onMessage(_ ws: WebSocket, _ session: Session, _ message: BSON) {
        
        switch message["action"].stringValue {
        
        
        default: self.sendError(ws, 400, "unknown action")
        }
    }
    
    private func onClose(_ session: Session, _ error: Error?) {
        guard let connection = session.connection else { return }
        _ = connection.close()
        session.connection = nil
    }
}
