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
        
        routes.webSocket("ws") { req, ws in
            
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
    
    private func send(_ ws: WebSocket, _ message: BSONDocument) {
        var message = message
        message["success"] = true
        try? ws.send(raw: encoder.encode(message), opcode: .text)
    }
    
    private func sendError(_ ws: WebSocket, _ errorCode: Int64, _ message: String, _ token: BSON) {
        let message: BSONDocument = ["success": false, "errorCode": .int64(errorCode), "message": .string(message), "token": token]
        try? ws.send(raw: encoder.encode(message), opcode: .text)
    }
}

extension WebSocketController {
    
    private func onMessage(_ ws: WebSocket, _ session: Session, _ message: BSON) {
        
        switch message["action"].stringValue {
        case "connect":
            
            guard let url = message["url"].stringValue.flatMap(URL.init(string:)) else {
                self.sendError(ws, 400, "invalid url", message["token"])
                return
            }
            
            Database.connect(url: url, on: ws.eventLoop).whenComplete {
                switch $0 {
                case let .success(connection):
                    
                    session.connection = connection
                    self.send(ws, ["token": message["token"]])
                    
                case let .failure(error): self.sendError(ws, 500, "\(error)", message["token"])
                }
            }
            
        case "runCommand":
            
            guard let connection = session.connection else {
                self.sendError(ws, 400, "database not connected", message["token"])
                return
            }
            
            if let sql = message["sql"].stringValue {
                
                connection.execute(SQLRaw(sql)).whenComplete {
                    switch $0 {
                    case let .success(rows):
                        
                        do {
                            
                            let result = try rows.map { try BSONDocument($0) }
                            
                            self.send(ws, ["token": message["token"], "result": result.toBSON()])
                            
                        } catch {
                            self.sendError(ws, 400, "\(error)", message["token"])
                        }
                        
                    case let .failure(error): self.sendError(ws, 500, "\(error)", message["token"])
                    }
                }
                
            } else if let command = message["mongoCommand"].documentValue {
                
                connection.mongoQuery().runCommand(command).whenComplete {
                    switch $0 {
                    case let .success(result): self.send(ws, ["token": message["token"], "result": .document(result)])
                    case let .failure(error): self.sendError(ws, 500, "\(error)", message["token"])
                    }
                }
                
            } else {
                self.sendError(ws, 400, "invalid action", message["token"])
            }
        
        default: self.sendError(ws, 400, "unknown action", message["token"])
        }
    }
    
    private func onClose(_ session: Session, _ error: Error?) {
        guard let connection = session.connection else { return }
        _ = connection.close()
        session.connection = nil
    }
}
