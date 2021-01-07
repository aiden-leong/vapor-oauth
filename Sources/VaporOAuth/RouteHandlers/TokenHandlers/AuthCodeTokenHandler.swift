import Vapor

struct AuthCodeTokenHandler {

    let clientValidator: ClientValidator
    let tokenManager: TokenManager
    let codeManager: CodeManager
    let codeValidator = CodeValidator()
    let tokenResponseGenerator: TokenResponseGenerator

    func handleAuthCodeTokenRequest(_ req: Request) throws -> EventLoopFuture<Response> {
        guard let codeString: String = req.query[OAuthRequestParameters.code] else {
            return try tokenResponseGenerator.createResponse(error: OAuthResponseParameters.ErrorType.invalidRequest,
                                                             description: "Request was missing the 'code' parameter")
        }

        guard let redirectURI: String = req.query[OAuthRequestParameters.redirectURI] else {
            return try tokenResponseGenerator.createResponse(error: OAuthResponseParameters.ErrorType.invalidRequest,
                                                             description: "Request was missing the 'redirect_uri' parameter")
        }

        guard let clientID: String = req.query[OAuthRequestParameters.clientID] else {
            return try tokenResponseGenerator.createResponse(error: OAuthResponseParameters.ErrorType.invalidRequest,
                                                             description: "Request was missing the 'client_id' parameter")
        }

        do {
            try clientValidator.authenticateClient(clientID: clientID,
                                                   clientSecret: req.query[OAuthRequestParameters.clientSecret],
                                                   grantType: .authorization)
        } catch {
            return try tokenResponseGenerator.createResponse(error: OAuthResponseParameters.ErrorType.invalidClient,
                                                             description: "Request had invalid client credentials", status: .unauthorized)
        }

        guard let code = codeManager.getCode(codeString),
            codeValidator.validateCode(code, clientID: clientID, redirectURI: redirectURI) else {
                let errorDescription = "The code provided was invalid or expired, or the redirect URI did not match"
                return try tokenResponseGenerator.createResponse(error: OAuthResponseParameters.ErrorType.invalidGrant,
                                                                 description: errorDescription)
        }

        codeManager.codeUsed(code)

        let scopes = code.scopes
        let expiryTime = 3600

        let (access, refresh) = try tokenManager.generateAccessRefreshTokens(clientID: clientID, userID: code.userID,
                                                                             scopes: scopes,
                                                                             accessTokenExpiryTime: expiryTime)

        return try tokenResponseGenerator.createResponse(accessToken: access, refreshToken: refresh, expiresIn: Int(expiryTime),
                                  scope: scopes?.joined(separator: " "))
    }
}
