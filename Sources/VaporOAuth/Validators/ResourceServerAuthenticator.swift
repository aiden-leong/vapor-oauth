import Vapor

struct ResourceServerAuthenticator {

    let resourceServerRetriever: ResourceServerRetriever

    func authenticate(_ req: Request, credentials: BasicAuthorization) -> EventLoopFuture<Void> {
        guard let resourceServer = resourceServerRetriever.getServer(credentials.username) else {
            return req.eventLoop.makeFailedFuture(Abort(.unauthorized))
        }

        guard String(bytes: resourceServer.password, encoding: .utf8) == credentials.password else {
            return req.eventLoop.makeFailedFuture(Abort(.unauthorized))
        }
        return req.eventLoop.future()
    }
}
