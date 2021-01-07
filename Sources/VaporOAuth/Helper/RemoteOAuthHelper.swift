import Vapor

class RemoteOAuthHelper: OAuthHelper {

    weak var request: Request?
    let tokenIntrospectionEndpoint: String
    let client: Client
    let resourceServerUsername: String
    let resourceServerPassword: String
    var remoteTokenResponse: RemoteTokenResponse?

    init(request: Request, tokenIntrospectionEndpoint: String, client: Client,
         resourceServerUsername: String, resourceServerPassword: String) {
        self.request = request
        self.tokenIntrospectionEndpoint = tokenIntrospectionEndpoint
        self.client = client
        self.resourceServerUsername = resourceServerUsername
        self.resourceServerPassword = resourceServerPassword
        self.remoteTokenResponse = nil
    }

    func assertScopes(_ scopes: [String]?) throws {
        if remoteTokenResponse == nil {
            try setupRemoteTokenResponse()
        }

        guard let remoteTokenResponse = remoteTokenResponse else {
            throw Abort(.internalServerError)
        }

        if let requiredScopes = scopes {
            guard let tokenScopes = remoteTokenResponse.scopes else {
                throw Abort(.unauthorized)
            }

            for scope in requiredScopes {
                if !tokenScopes.contains(scope) {
                    throw Abort(.unauthorized)
                }
            }
        }

    }

    func user() throws -> OAuthUser {
        if remoteTokenResponse == nil {
            try setupRemoteTokenResponse()
        }

        guard let remoteTokenResponse = remoteTokenResponse else {
            throw Abort(.internalServerError)
        }

        guard let user = remoteTokenResponse.user else {
            throw Abort(.unauthorized)
        }

        return user
    }

    private func setupRemoteTokenResponse() throws {
        guard let token = try request?.getOAuthToken() else {
            throw Abort(.forbidden)
        }
        let tokenRequest = Request(method: .post, uri: tokenIntrospectionEndpoint)
        var tokenRequestJSON = JSON()
        try tokenRequestJSON.set("token", token)
        tokenRequest.json = tokenRequestJSON

        let resourceAuthHeader = "\(resourceServerUsername):\(resourceServerPassword)".makeBytes().base64Encoded.makeString()
        tokenRequest.headers[.authorization] = "Basic \(resourceAuthHeader)"

        let tokenInfoResponse = try client.respond(to: tokenRequest)
//        client.post(URI(string: tokenIntrospectionEndpoint)) {
//            req in
//
//        }

        guard let tokenInfoJSON = tokenInfoResponse.json else {
            throw Abort(.internalServerError)
        }

        guard let tokenActive = tokenInfoJSON[OAuthResponseParameters.active]?.bool, tokenActive else {
            throw Abort(.unauthorized)
        }

        var scopes: [String]?
        var oauthUser: OAuthUser?

        if let tokenScopes = tokenInfoJSON[OAuthResponseParameters.scope] {
            scopes = tokenScopes.components(separatedBy: " ")
        }

        if let userID = tokenInfoJSON[OAuthResponseParameters.userID] {
            guard let username = tokenInfoJSON[OAuthResponseParameters.username] else {
                throw Abort(.internalServerError)
            }
            let userIdentifier: UUID = UUID(userID, in: nil)
            oauthUser = OAuthUser(userID: userIdentifier, username: username,
                    emailAddress: tokenInfoJSON[OAuthResponseParameters.email],
                    password: "".makeBytes())
        }

        self.remoteTokenResponse = RemoteTokenResponse(scopes: scopes, user: oauthUser)

    }
}

struct RemoteTokenResponse {
    let scopes: [String]?
    let user: OAuthUser?
}
