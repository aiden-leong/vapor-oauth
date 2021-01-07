import Vapor

struct VaporOAuth2HelperKey: StorageKey {
    typealias Value = VaporOAuth2Helper
}

public final class VaporOAuth2Helper {

    public static func setup(for req: Request, tokenIntrospectionEndpoint: String, client: Client,
                             resourceServerUsername: String, resourceServerPassword: String) {
        let helper = VaporOAuth2Helper(req: req, tokenIntrospectionEndpoint: tokenIntrospectionEndpoint, client: client,
                            resourceServerUsername: resourceServerUsername, resourceServerPassword: resourceServerPassword)
        req.storage[VaporOAuth2HelperKey] = helper
    }

    let oauthHelper: OAuthHelper

    init(req: Request, provider: OAuth2Provider?) {
        self.oauthHelper = LocalOAuthHelper(req: req, tokenAuthenticator: provider?.tokenHandler.tokenAuthenticator,
                                            userManager: provider?.userManager, tokenManager: provider?.tokenManager)
    }

    init(req: Request, tokenIntrospectionEndpoint: String, client: Client,
         resourceServerUsername: String, resourceServerPassword: String) {
        self.oauthHelper = RemoteOAuthHelper(req: req, tokenIntrospectionEndpoint: tokenIntrospectionEndpoint,
                                             client: client, resourceServerUsername: resourceServerUsername,
                                             resourceServerPassword: resourceServerPassword)
    }

    public func assertScopes(_ req: Request, scopes: [String]?) -> EventLoopFuture<Void> {
        return oauthHelper.assertScopes(req, scopes: scopes)
    }

    public func user(_ req: Request) throws -> EventLoopFuture<OAuthUser> {
        return try oauthHelper.user(req)
    }
}

extension Request {
    public var oauth: VaporOAuth2Helper {
        if let existing = storage[VaporOAuth2HelperKey] {
            return existing
        }

        let helper = VaporOAuth2Helper(req: self, provider: Request.oauthProvider)
        storage[VaporOAuth2HelperKey] = helper

        return helper
    }

    static var oauthProvider: OAuth2Provider?
}

extension Request {
    func getOAuthToken(_ req: Request) -> EventLoopFuture<String> {
        let authHeader = headers[.authorization][0]

        guard authHeader.lowercased().hasPrefix("bearer ") else {
            return req.eventLoop.makeFailedFuture(Abort(.forbidden))
        }

        let token = String(authHeader[authHeader.index(authHeader.startIndex, offsetBy: 7)...])

        guard !token.isEmpty else {
            return req.eventLoop.makeFailedFuture(Abort(.forbidden))
        }

        return req.eventLoop.future(token)
    }
}
