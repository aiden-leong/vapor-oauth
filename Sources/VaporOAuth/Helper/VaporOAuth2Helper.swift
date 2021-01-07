import Vapor

struct VaporOAuth2HelperKey: StorageKey {
    typealias Value = VaporOAuth2Helper
}

public final class VaporOAuth2Helper {

    public static func setup(for request: Request, tokenIntrospectionEndpoint: String, client: String,
                             resourceServerUsername: String, resourceServerPassword: String) {
        let helper = VaporOAuth2Helper(request: request, tokenIntrospectionEndpoint: tokenIntrospectionEndpoint, client: client,
                            resourceServerUsername: resourceServerUsername, resourceServerPassword: resourceServerPassword)
        request.storage[VaporOAuth2HelperKey] = helper
    }

    let oauthHelper: OAuthHelper

    init(request: Request, provider: OAuth2Provider?) {
        self.oauthHelper = LocalOAuthHelper(request: request, tokenAuthenticator: provider?.tokenHandler.tokenAuthenticator,
                                            userManager: provider?.userManager, tokenManager: provider?.tokenManager)
    }

    init(request: Request, tokenIntrospectionEndpoint: String, client: String,
         resourceServerUsername: String, resourceServerPassword: String) {
        self.oauthHelper = RemoteOAuthHelper(request: request, tokenIntrospectionEndpoint: tokenIntrospectionEndpoint,
                                             client: client, resourceServerUsername: resourceServerUsername,
                                             resourceServerPassword: resourceServerPassword)
    }

    public func assertScopes(_ scopes: [String]?) throws {
        try oauthHelper.assertScopes(scopes)
    }

    public func user() throws -> OAuthUser {
        return try oauthHelper.user()
    }
}

extension Request {
    public var oauth: VaporOAuth2Helper {
        if let existing = storage[VaporOAuth2HelperKey] {
            return existing
        }

        let helper = VaporOAuth2Helper(request: self, provider: Request.oauthProvider)
        storage[VaporOAuth2HelperKey] = helper

        return helper
    }

    static var oauthProvider: OAuth2Provider?
}

extension Request {
    func getOAuthToken() throws -> String {
        guard let authHeader = headers[.authorization] else {
            throw Abort(.forbidden)
        }

        guard authHeader.lowercased().hasPrefix("bearer ") else {
            throw Abort(.forbidden)
        }

        #if swift(>=4)
        let token = String(authHeader[authHeader.index(authHeader.startIndex, offsetBy: 7)...])
        #else
        let token = authHeader.substring(from: authHeader.index(authHeader.startIndex, offsetBy: 7))
        #endif

        guard !token.isEmpty else {
            throw Abort(.forbidden)
        }

        return token
    }
}
