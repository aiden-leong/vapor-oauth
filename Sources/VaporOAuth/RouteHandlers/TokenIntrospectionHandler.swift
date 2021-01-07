import Vapor

struct OAuthResponse: Codable {
    var error: String?
    var errorDescription: String?
    var active: String?
}

struct TokenIntrospectionHandler {

    let clientValidator: ClientValidator
    let tokenManager: TokenManager
    let userManager: UserManager

    func handleRequest(_ req: Request) throws -> Response {
        guard let tokenString: String = req.query[OAuthRequestParameters.token] else {
            return try createErrorResponse(status: .badRequest,
                                           errorMessage: OAuthResponseParameters.ErrorType.missingToken,
                                           errorDescription: "The token parameter is required")
        }

        guard let token = tokenManager.getAccessToken(tokenString) else {
            return try createTokenResponse(active: false, expiryDate: nil, clientID: nil)
        }

        guard token.expiryTime >= Date() else {
            return try createTokenResponse(active: false, expiryDate: nil, clientID: nil)
        }

        let scopes = token.scopes?.joined(separator: " ")
        var user: OAuthUser? = nil

        if let userID = token.userID {
            if let tokenUser = userManager.getUser(userID: userID) {
                user = tokenUser
            }
        }

        return try createTokenResponse(active: true, expiryDate: token.expiryTime, clientID: token.clientID,
                                       scopes: scopes, user: user)
    }

    func createTokenResponse(active: Bool, expiryDate: Date?, clientID: String?, scopes: String? = nil,
                             user: OAuthUser? = nil) throws -> Response {
        var oauthResponse = OAuthResponse(active: active)

        if let clientID = clientID {
            try json.set(OAuthResponseParameters.clientID, clientID)
        }

        if let scopes = scopes {
            try json.set(OAuthResponseParameters.scope, scopes)
        }

        if let user = user {
            try json.set(OAuthResponseParameters.userID, user.id)
            try json.set(OAuthResponseParameters.username, user.username)
            if let email = user.emailAddress {
                try json.set(OAuthResponseParameters.email, email)
            }
        }

        if let expiryDate = expiryDate {
            try json.set(OAuthResponseParameters.expiry, Int(expiryDate.timeIntervalSince1970))
        }

        let response = Response(status: .ok)
        response.json = json
        return response
    }

    func createErrorResponse(status: HTTPStatus, errorMessage: String, errorDescription: String) throws -> Response {
        var json = OAuthResponse(error: errorMessage, errorDescription: errorDescription)
        let response = Response(status: status)
        response.json = json
        return response
    }
}
