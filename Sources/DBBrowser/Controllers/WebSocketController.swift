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
    
    enum DatabaseType {
        
        case sql
        
        case mongo
    }
    
    private class Session {
        
        var connection: DBConnection?
        
        var type: DatabaseType?
    }
}

extension WebSocketController {
    
    private func send(_ ws: WebSocket, _ message: BSONDocument) {
        try? ws.send(raw: encoder.encode(message), opcode: .text)
    }
}

extension WebSocketController {
    
    private func onMessage(_ ws: WebSocket, _ session: Session, _ message: BSON) {
        
        switch message["action"].stringValue {
        case "connect":
            
            guard let url = message["url"].stringValue.flatMap(URL.init(string:)) else {
                self.send(ws, ["success": false, "token": message["token"], "error": .string("invalid url")])
                return
            }
            
            Database.connect(url: url, on: ws.eventLoop).whenComplete {
                switch $0 {
                case let .success(connection):
                    
                    if url.scheme == "mongodb" {
                        session.type = .mongo
                    } else if connection is DBSQLConnection {
                        session.type = .sql
                    }
                    
                    session.connection = connection
                    self.send(ws, ["success": true, "token": message["token"]])
                    
                case let .failure(error): self.send(ws, ["success": false, "token": message["token"], "error": .string("\(error)")])
                }
            }
            
        case "databases":
            
            guard let connection = session.connection else {
                self.send(ws, ["success": false, "token": message["token"], "error": .string("database not connected")])
                return
            }
            
            connection.databases().whenComplete {
                switch $0 {
                case let .success(result): self.send(ws, ["success": true, "token": message["token"], "databases": BSON(result)])
                case let .failure(error): self.send(ws, ["success": false, "token": message["token"], "error": .string("\(error)")])
                }
            }
            
        case "tables":
            
            switch session.type {
            case .sql:
                
                guard let connection = session.connection as? DBSQLConnection else {
                    self.send(ws, ["success": false, "token": message["token"], "error": .string("database not connected")])
                    return
                }
                
                connection.tables().whenComplete {
                    switch $0 {
                    case let .success(tables): self.send(ws, ["success": true, "token": message["token"], "tables": BSON(tables)])
                    case let .failure(error): self.send(ws, ["success": false, "token": message["token"], "error": .string("\(error)")])
                    }
                }
                
            case .mongo:
                
                guard let connection = session.connection else {
                    self.send(ws, ["success": false, "token": message["token"], "error": .string("database not connected")])
                    return
                }
                
                connection.mongoQuery().collections().execute()
                    .flatMap { $0.toArray() }
                    .map { $0.map { $0.name } }
                    .whenComplete {
                        switch $0 {
                        case let .success(tables): self.send(ws, ["success": true, "token": message["token"], "tables": BSON(tables)])
                        case let .failure(error): self.send(ws, ["success": false, "token": message["token"], "error": .string("\(error)")])
                        }
                    }
                
            default: self.send(ws, ["success": false, "token": message["token"], "error": .string("unknown error")])
            }
            
        case "runCommand":
            
            switch session.type {
            case .sql:
                
                guard let connection = session.connection as? DBSQLConnection else {
                    self.send(ws, ["success": false, "token": message["token"], "error": .string("database not connected")])
                    return
                }
                
                guard let command = message["command"].stringValue else {
                    self.send(ws, ["success": false, "token": message["token"], "error": .string("invalid command")])
                    return
                }
                
                connection.execute(SQLRaw(command)).whenComplete {
                    switch $0 {
                    case let .success(rows):
                        
                        do {
                            
                            let result = try rows.map { try BSONDocument($0) }
                            
                            self.send(ws, ["success": true, "token": message["token"], "data": result.toBSON()])
                            
                        } catch {
                            self.send(ws, ["success": false, "token": message["token"], "error": .string("\(error)")])
                        }
                        
                    case let .failure(error): self.send(ws, ["success": false, "token": message["token"], "error": .string("\(error)")])
                    }
                }
                
            case .mongo:
                
                guard let connection = session.connection else {
                    self.send(ws, ["success": false, "token": message["token"], "error": .string("database not connected")])
                    return
                }
                
                guard let command = message["command"].documentValue else {
                    self.send(ws, ["success": false, "token": message["token"], "error": .string("invalid command")])
                    return
                }
                connection.mongoQuery().runCommand(command).whenComplete {
                    switch $0 {
                    case let .success(result): self.send(ws, ["success": true, "token": message["token"], "data": .document(result)])
                    case let .failure(error): self.send(ws, ["success": false, "token": message["token"], "error": .string("\(error)")])
                    }
                }
                
            default: self.send(ws, ["success": false, "token": message["token"], "error": .string("unknown error")])
            }
            
        default: self.send(ws, ["success": false, "token": message["token"], "error": .string("unknown action")])
        }
    }
    
    private func onClose(_ session: Session, _ error: Error?) {
        guard let connection = session.connection else { return }
        _ = connection.close()
        session.connection = nil
    }
}
