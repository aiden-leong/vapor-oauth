import Vapor

struct TokenIntrospectionAuthMiddleware: Middleware {


    let resourceServerAuthenticator: ResourceServerAuthenticator

    public func respond(to req: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        guard let basicAuthorization = req.headers.basicAuthorization else {
            return req.eventLoop.future(error: Abort(.unauthorized))
        }
        return resourceServerAuthenticator.authenticate(req, credentials: basicAuthorization)
                .flatMap {
                    return next.respond(to: req)
                }
    }
}
