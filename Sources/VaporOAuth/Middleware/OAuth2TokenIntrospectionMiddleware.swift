//import Vapor
//
//public struct OAuth2TokenIntrospectionMiddleware: Middleware {
//
//
//    let tokenIntrospectionEndpoint: String
//    let requiredScopes: [String]?
//    let client: String
//    let resourceServerUsername: String
//    let resourceServerPassword: String
//
//    public init(tokenIntrospectionEndpoint: String, requiredScopes: [String]?, client: String,
//                resourceServerUsername: String, resourceServerPassword: String) {
//        self.tokenIntrospectionEndpoint = tokenIntrospectionEndpoint
//        self.requiredScopes = requiredScopes
//        self.client = client
//        self.resourceServerUsername = resourceServerUsername
//        self.resourceServerPassword = resourceServerPassword
//    }
//
//    public func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
//        Helper.setup(for: request, tokenIntrospectionEndpoint: tokenIntrospectionEndpoint, client: client,
//                     resourceServerUsername: resourceServerUsername, resourceServerPassword: resourceServerPassword)
//        do {
//            try request.oauth.assertScopes(requiredScopes)
//        } catch {
//            return request.eventLoop.future(error: Abort(.unauthorized, reason: "TODO TODO TODO"))
//        }
//        return next.respond(to: request)
//    }
//}
