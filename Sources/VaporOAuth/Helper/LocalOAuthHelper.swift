import Vapor

struct LocalOAuthHelper: OAuthHelper {

    weak var req: Request?
    let tokenAuthenticator: TokenAuthenticator?
    let userManager: UserManager?
    let tokenManager: TokenManager?

    func assertScopes(_ req: Request, scopes: [String]?) -> EventLoopFuture<Void> {
        guard let tokenAuthenticator = tokenAuthenticator else {
            return req.eventLoop.makeFailedFuture(Abort(.forbidden))
        }

        return getToken(req).flatMap { token in
            guard tokenAuthenticator.validateAccessToken(token, requiredScopes: scopes) else {
                return req.eventLoop.makeFailedFuture(Abort(.unauthorized))
            }
            return req.eventLoop.future() 
        }

        
    }

    func user(_ req: Request) -> EventLoopFuture<OAuthUser> {
        guard let userManager = userManager else {
            return req.eventLoop.makeFailedFuture(Abort(.forbidden))
        }

        return getToken(req)
            .flatMap { token -> EventLoopFuture<UUID> in
                guard let userID = token.userID else {
                    return req.eventLoop.makeFailedFuture(Abort(.unauthorized))
                }
                return req.eventLoop.future(userID)
            }
            .flatMap { userID in
                guard let user = userManager.getUser(userID: userID) else {
                    return req.eventLoop.makeFailedFuture(Abort(.unauthorized))
                }
                return req.eventLoop.future(user)
            }
    }

    private func getToken(_ req: Request) -> EventLoopFuture<AccessToken> {
        guard let tokenManager = tokenManager else {
            return req.eventLoop.makeFailedFuture(Abort(.forbidden))
        }

        return req.getOAuthToken(req)
                .flatMap { token -> EventLoopFuture<AccessToken> in
                    guard let accessToken = tokenManager.getAccessToken(token) else {
                        return req.eventLoop.makeFailedFuture(Abort(.unauthorized))
                    }
                    return req.eventLoop.future(accessToken)
                }
                .flatMap { accessToken in
                    if (accessToken.expiryTime >= Date()) {
                        return req.eventLoop.future(accessToken)
                    } else {
                        return req.eventLoop.makeFailedFuture(Abort(.unauthorized))
                    }
                }
    }
}
