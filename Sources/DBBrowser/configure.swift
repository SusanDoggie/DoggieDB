import Vapor

public func configure(_ app: Application) throws {
    
    let publicDirectory = Bundle.module.resourceURL!.appendingPathComponent("Public")
    app.middleware.use(FileMiddleware(publicDirectory: publicDirectory.path))
    
    try routes(app)
}
