import Vapor

struct ResourceServerAuthenticator {

    let resourceServerRetriever: ResourceServerRetriever

    func authenticate(credentials: BasicAuthorization) throws {
        guard let resourceServer = resourceServerRetriever.getServer(credentials.username) else {
            throw Abort(.unauthorized)
        }

        guard String(bytes: resourceServer.password, encoding: .utf8) == credentials.password else {
            throw Abort(.unauthorized)
        }
    }
}
