import Vapor

struct AuthorizePostRequest {
    let user: OAuthUser
    let userID: UUID
    let redirectURIBaseString: String
    let approveApplication: Bool
    let clientID: String
    let responseType: String
    let csrfToken: String
    let scopes: [String]?
}

struct AuthorizePostHandler {

    let tokenManager: TokenManager
    let codeManager: CodeManager
    let clientValidator: ClientValidator

    func handleRequest(req: Request) throws -> Response {
        let requestObject = try validateAuthPostRequest(req)
        var redirectURI = requestObject.redirectURIBaseString

        do {
            try clientValidator.validateClient(clientID: requestObject.clientID, responseType: requestObject.responseType,
                               redirectURI: requestObject.redirectURIBaseString, scopes: requestObject.scopes)
        } catch is AbortError {
            throw Abort(.forbidden)
        } catch {
            req.eventLoop.makeFailedFuture(Abort(.badRequest))
        }

        guard req.session.data[SessionData.csrfToken] == requestObject.csrfToken else {
            req.eventLoop.makeFailedFuture(Abort(.badRequest))
        }

        if requestObject.approveApplication {
            if requestObject.responseType == ResponseType.token {
                let accessToken = try tokenManager.generateAccessToken(clientID: requestObject.clientID,
                                                                       userID: requestObject.userID,
                                                                       scopes: requestObject.scopes, expiryTime: 3600)
                redirectURI += "#token_type=bearer&access_token=\(accessToken.tokenString)&expires_in=3600"
            } else if requestObject.responseType == ResponseType.code {
                let generatedCode = try codeManager.generateCode(userID: requestObject.userID,
                                                                 clientID: requestObject.clientID,
                                                                 redirectURI: requestObject.redirectURIBaseString,
                                                                 scopes: requestObject.scopes)
                redirectURI += "?code=\(generatedCode)"
            } else {
                redirectURI += "?error=invalid_request&error_description=unknown+response+type"
            }
        } else {
            redirectURI += "?error=access_denied&error_description=user+denied+the+req"
        }

        if let requestedScopes = requestObject.scopes {
            if !requestedScopes.isEmpty {
                redirectURI += "&scope=\(requestedScopes.joined(separator: "+"))"
            }
        }

        if let state: String = req.query[OAuthRequestParameters.state] {
            redirectURI += "&state=\(state)"
        }

        return req.redirect(to: redirectURI)
    }

    private func validateAuthPostRequest(_ req: Request) throws -> AuthorizePostRequest {
        var user: OAuthUser
        do {
            user = try req.auth.require(OAuthUser.self)
        } catch {
            req.eventLoop.makeFailedFuture(Abort(.unauthorized))
        }

        guard let userID = user.id else {
            req.eventLoop.makeFailedFuture(Abort(.unauthorized))
        }

        guard let redirectURIBaseString: String = req.query[OAuthRequestParameters.redirectURI] else {
            req.eventLoop.makeFailedFuture(Abort(.badRequest))
        }

        guard let approveApplication: Bool = req.query[OAuthRequestParameters.applicationAuthorized] else {
            req.eventLoop.makeFailedFuture(Abort(.badRequest))
        }

        guard let clientID: String = req.query[OAuthRequestParameters.clientID] else {
            req.eventLoop.makeFailedFuture(Abort(.badRequest))
        }

        guard let responseType: String = req.query[OAuthRequestParameters.responseType] else {
            req.eventLoop.makeFailedFuture(Abort(.badRequest))
        }

        guard let csrfToken: String = req.query[OAuthRequestParameters.csrfToken] else {
            req.eventLoop.makeFailedFuture(Abort(.badRequest))
        }

        let scopes: [String]?

        if let scopeQuery: String = req.query[OAuthRequestParameters.scope] {
            scopes = scopeQuery.components(separatedBy: " ")
        } else {
            scopes = nil
        }

        return AuthorizePostRequest(user: user, userID: userID, redirectURIBaseString: redirectURIBaseString,
                                    approveApplication: approveApplication, clientID: clientID,
                                    responseType: responseType, csrfToken: csrfToken, scopes: scopes)
    }

}
