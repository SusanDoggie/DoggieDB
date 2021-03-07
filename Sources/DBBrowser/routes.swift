import Vapor

func routes(_ app: Application) throws {
    
    app.get { req -> Response in
        let publicDirectory = Bundle.module.resourceURL!.appendingPathComponent("Public")
        return req.fileio.streamFile(at: publicDirectory.appendingPathComponent("index.html").path)
    }
    
    app.get("**") { req -> Response in
        let publicDirectory = Bundle.module.resourceURL!.appendingPathComponent("Public")
        return req.fileio.streamFile(at: publicDirectory.appendingPathComponent("index.html").path)
    }
}
