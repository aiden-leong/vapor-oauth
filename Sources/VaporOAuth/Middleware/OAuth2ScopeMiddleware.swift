import Vapor

public struct OAuth2ScopeMiddleware: Middleware {
    let requiredScopes: [String]?

    public init(requiredScopes: [String]?) {
        self.requiredScopes = requiredScopes
    }

    public func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        do {
            try request.oauth.assertScopes(requiredScopes)
        } catch {
            return request.eventLoop.future(error: Abort(.unauthorized, reason: "TODO TODO TODO"))
        }
        return next.respond(to: request)
    }
}
