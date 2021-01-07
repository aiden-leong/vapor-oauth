import Vapor

struct PasswordTokenHandler {

    let clientValidator: ClientValidator
    let scopeValidator: ScopeValidator
    let userManager: UserManager
    let log: Logger
    let tokenManager: TokenManager
    let tokenResponseGenerator: TokenResponseGenerator

    func handlePasswordTokenRequest(_ request: Request) throws -> Response {
        guard let username: String = request.query[OAuthRequestParameters.usernname] else {
            return try tokenResponseGenerator.createResponse(error: OAuthResponseParameters.ErrorType.invalidRequest,
                                                             description: "Request was missing the 'username' parameter")
        }

        guard let password: String = request.query[OAuthRequestParameters.password] else {
            return try tokenResponseGenerator.createResponse(error: OAuthResponseParameters.ErrorType.invalidRequest,
                                                             description: "Request was missing the 'password' parameter")
        }

        guard let clientID: String = request.query[OAuthRequestParameters.clientID] else {
            return try tokenResponseGenerator.createResponse(error: OAuthResponseParameters.ErrorType.invalidRequest,
                                                             description: "Request was missing the 'client_id' parameter")
        }

        do {
            try clientValidator.authenticateClient(clientID: clientID,
                                                   clientSecret: request.query[OAuthRequestParameters.clientSecret],
                                                   grantType: .password)
        } catch ClientError.unauthorized {
            return try tokenResponseGenerator.createResponse(error: OAuthResponseParameters.ErrorType.invalidClient,
                                                             description: "Request had invalid client credentials", status: .unauthorized)
        } catch ClientError.notFirstParty {
            return try tokenResponseGenerator.createResponse(error: OAuthResponseParameters.ErrorType.unauthorizedClient,
                                                             description: "Password Credentials grant is not allowed")
        }

        let scopeString: String? = request.query[OAuthRequestParameters.scope]

        if let scopes = scopeString {
            do {
                try scopeValidator.validateScope(clientID: clientID, scopes: scopes.components(separatedBy: " "))
            } catch ScopeError.invalid {
                return try tokenResponseGenerator.createResponse(error: OAuthResponseParameters.ErrorType.invalidScope,
                                                                 description: "Request contained an invalid scope")
            } catch ScopeError.unknown {
                return try tokenResponseGenerator.createResponse(error: OAuthResponseParameters.ErrorType.invalidScope,
                                                                 description: "Request contained an unknown scope")
            }
        }

        guard let userID = userManager.authenticateUser(username: username, password: password) else {
            log.warning("LOGIN WARNING: Invalid login attempt for user \(username)")
            return try tokenResponseGenerator.createResponse(error: OAuthResponseParameters.ErrorType.invalidGrant,
                                                             description: "Request had invalid credentials")
        }

        let expiryTime = 3600
        let scopes = scopeString?.components(separatedBy: " ")

        let (access, refresh) = try tokenManager.generateAccessRefreshTokens(clientID: clientID, userID: userID,
                                                                             scopes: scopes,
                                                                             accessTokenExpiryTime: expiryTime)

        return try tokenResponseGenerator.createResponse(accessToken: access, refreshToken: refresh,
                                                         expiresIn: expiryTime, scope: scopeString)
    }
}
