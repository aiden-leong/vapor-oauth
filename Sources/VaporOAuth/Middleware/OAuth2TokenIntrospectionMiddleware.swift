import Vapor

public struct OAuth2TokenIntrospectionMiddleware: Middleware {


    let tokenIntrospectionEndpoint: String
    let requiredScopes: [String]?
    let client: Client
    let resourceServerUsername: String
    let resourceServerPassword: String

    public init(tokenIntrospectionEndpoint: String, requiredScopes: [String]?, client: Client,
                resourceServerUsername: String, resourceServerPassword: String) {
        self.tokenIntrospectionEndpoint = tokenIntrospectionEndpoint
        self.requiredScopes = requiredScopes
        self.client = client
        self.resourceServerUsername = resourceServerUsername
        self.resourceServerPassword = resourceServerPassword
    }

    public func respond(to req: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        VaporOAuth2Helper.setup(for: req, tokenIntrospectionEndpoint: tokenIntrospectionEndpoint, client: client,
                     resourceServerUsername: resourceServerUsername, resourceServerPassword: resourceServerPassword)
        return req.oauth.assertScopes(req, scopes: requiredScopes)
                .flatMap {
                    return next.respond(to: req)
                }
    }
}
