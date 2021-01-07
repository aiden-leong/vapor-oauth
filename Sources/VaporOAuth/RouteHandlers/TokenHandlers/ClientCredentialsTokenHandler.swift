import Vapor

struct ClientCredentialsTokenHandler {

    let clientValidator: ClientValidator
    let scopeValidator: ScopeValidator
    let tokenManager: TokenManager
    let tokenResponseGenerator: TokenResponseGenerator

    func handleClientCredentialsTokenRequest(_ req: Request) throws -> EventLoopFuture<Response> {
        guard let clientID: String = req.query[OAuthRequestParameters.clientID] else {
            return try tokenResponseGenerator.createResponse(req, error: OAuthResponseParameters.ErrorType.invalidRequest,
                                                             description: "Request was missing the 'client_id' parameter")
        }

        guard let clientSecret: String = req.query[OAuthRequestParameters.clientSecret] else {
            return try tokenResponseGenerator.createResponse(req, error: OAuthResponseParameters.ErrorType.invalidRequest,
                                                             description: "Request was missing the 'client_secret' parameter")
        }

        do {
            try clientValidator.authenticateClient(clientID: clientID, clientSecret: clientSecret,
                                                   grantType: .clientCredentials, checkConfidentialClient: true)
        } catch ClientError.unauthorized {
            return try tokenResponseGenerator.createResponse(req, error: OAuthResponseParameters.ErrorType.invalidClient,
                                                             description: "Request had invalid client credentials", status: .unauthorized)
        } catch ClientError.notConfidential {
            return try tokenResponseGenerator.createResponse(req, error: OAuthResponseParameters.ErrorType.unauthorizedClient,
                                                             description: "You are not authorized to use the Client Credentials grant type")
        }

        let scopeString: String? = req.query[OAuthRequestParameters.scope]
        if let scopes = scopeString {
            do {
                try scopeValidator.validateScope(clientID: clientID, scopes: scopes.components(separatedBy: " "))
            } catch ScopeError.invalid {
                return try tokenResponseGenerator.createResponse(req, error: OAuthResponseParameters.ErrorType.invalidScope,
                                                                 description: "Request contained an invalid scope")
            } catch ScopeError.unknown {
                return try tokenResponseGenerator.createResponse(req, error: OAuthResponseParameters.ErrorType.invalidScope,
                                                                 description: "Request contained an unknown scope")
            }
        }

        let expiryTime = 3600
        let scopes = scopeString?.components(separatedBy: " ")
        let (access, refresh) = try tokenManager.generateAccessRefreshTokens(clientID: clientID, userID: nil,
                                                                             scopes: scopes,
                                                                             accessTokenExpiryTime: expiryTime)

        return try tokenResponseGenerator.createResponse(req, accessToken: access, refreshToken: refresh,
                                                         expiresIn: expiryTime, scope: scopeString)
    }
}
