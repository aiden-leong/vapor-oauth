//import Vapor
//
//struct TokenIntrospectionAuthMiddleware: Middleware {
//
//
//    let resourceServerAuthenticator: ResourceServerAuthenticator
//
//    public func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
//        guard let basicAuthorization = request.headers.basicAuthorization else {
//            return request.eventLoop.future(error: Abort(.unauthorized))
//        }
//        do {
//            try resourceServerAuthenticator.authenticate(credentials: basicAuthorization)
//        } catch {
//            return request.eventLoop.future(error: Abort(.unauthorized, reason: "TODO TODO TODO"))
//        }
//        return next.respond(to: request)
//    }
//}
