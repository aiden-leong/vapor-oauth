 import Vapor

 public struct OAuth2ScopeMiddleware: Middleware {
     let requiredScopes: [String]?

     public init(requiredScopes: [String]?) {
         self.requiredScopes = requiredScopes
     }

     public func respond(to req: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
         return req.oauth.assertScopes(req, scopes: requiredScopes)
             .flatMap {
                 return next.respond(to: req)
             }
     }
 }
