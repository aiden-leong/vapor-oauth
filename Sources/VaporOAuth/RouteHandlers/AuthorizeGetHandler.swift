import Vapor

struct AuthorizeGetHandler {

    let authorizeHandler: AuthorizeHandler
    let clientValidator: ClientValidator

    func handleRequest(_ req: Request) throws -> Response {
        let (errorResponse, createdAuthRequestObject) = try validateRequest(req)

        if let errorResponseReturned = errorResponse {
            return errorResponseReturned
        }

        guard let authRequestObject = createdAuthRequestObject else {
            throw Abort(.internalServerError)
        }

        do {
            try clientValidator.validateClient(clientID: authRequestObject.clientID, responseType: authRequestObject.responseType,
                    redirectURI: authRequestObject.redirectURIString, scopes: authRequestObject.scopes)
        } catch AuthorizationError.invalidClientID {
            return try authorizeHandler.handleAuthorizationError(.invalidClientID)
        } catch AuthorizationError.invalidRedirectURI {
            return try authorizeHandler.handleAuthorizationError(.invalidRedirectURI)
        } catch ScopeError.unknown {
            return createErrorResponse(
                    req: req,
                    redirectURI: authRequestObject.redirectURIString,
                    errorType: OAuthResponseParameters.ErrorType.invalidScope,
                    errorDescription: "scope+is+unknown",
                    state: authRequestObject.state
            )
        } catch ScopeError.invalid {
            return createErrorResponse(
                    req: req,
                    redirectURI: authRequestObject.redirectURIString,
                    errorType: OAuthResponseParameters.ErrorType.invalidScope,
                    errorDescription: "scope+is+invalid",
                    state: authRequestObject.state
            )
        } catch AuthorizationError.confidentialClientTokenGrant {
            return createErrorResponse(
                    req: req,
                    redirectURI: authRequestObject.redirectURIString,
                    errorType: OAuthResponseParameters.ErrorType.unauthorizedClient,
                    errorDescription: "token+grant+disabled+for+confidential+clients",
                    state: authRequestObject.state
            )
        } catch AuthorizationError.httpRedirectURI {
            return try authorizeHandler.handleAuthorizationError(.httpRedirectURI)
        }

        let redirectURI = URI(string: authRequestObject.redirectURIString)
        let csrfToken = String(Int.random(in: 1..<999999))
        // let csrfToken = Random.bytes(count: 32).hexString

        let session = req.session

        session.data[SessionData.csrfToken] = csrfToken
        
        let authorizationRequestObject = AuthorizationRequestObject(responseType: authRequestObject.responseType,
                clientID: authRequestObject.clientID, redirectURI: redirectURI,
                scope: authRequestObject.scopes, state: authRequestObject.state,
                csrfToken: csrfToken)

        let bodyString = try authorizeHandler.handleAuthorizationRequest(req, authorizationRequestObject: authorizationRequestObject)

        let headers = HTTPHeaders()
        let body = Response.Body(string: bodyString)
        let response = Response(status: .ok, version: .init(major: 1, minor: 1), headers: headers, body: body)
        return  response
    }

    private func validateRequest(_ req: Request) throws -> (Response?, AuthorizationGetRequestObject?) {
        guard let clientID: String = req.query[OAuthRequestParameters.clientID] else {
            return (try authorizeHandler.handleAuthorizationError(.invalidClientID), nil)
        }

        guard let redirectURIString: String = req.query[OAuthRequestParameters.redirectURI] else {
            return (try authorizeHandler.handleAuthorizationError(.invalidRedirectURI), nil)
        }

        let scopes: [String]

        if let scopeQuery: String = req.query[OAuthRequestParameters.scope] {
            scopes = scopeQuery.components(separatedBy: " ")
        } else {
            scopes = []
        }

        guard let state: String = req.query[OAuthRequestParameters.state] else {
            return (try authorizeHandler.handleAuthorizationError(.invalidRedirectURI), nil)
        }

        guard let responseType: String = req.query[OAuthRequestParameters.responseType] else {
            let errorResponse = createErrorResponse(
                    req: req,
                    redirectURI: redirectURIString,
                    errorType: OAuthResponseParameters.ErrorType.invalidRequest,
                    errorDescription: "Request+was+missing+the+response_type+parameter",
                    state: state
            )
            return (errorResponse, nil)
        }

        guard responseType == ResponseType.code || responseType == ResponseType.token else {
            let errorResponse = createErrorResponse(
                    req: req,
                    redirectURI: redirectURIString,
                    errorType: OAuthResponseParameters.ErrorType.invalidRequest,
                    errorDescription: "invalid+response+type", state: state
            )
            return (errorResponse, nil)
        }

        let authRequestObject = AuthorizationGetRequestObject(clientID: clientID, redirectURIString: redirectURIString,
                scopes: scopes, state: state,
                responseType: responseType)

        return (nil, authRequestObject)
    }

    private func createErrorResponse(req: Request, redirectURI: String, errorType: String, errorDescription: String,
                                     state: String?) -> Response {
        var redirectString = "\(redirectURI)?error=\(errorType)&error_description=\(errorDescription)"

        if let state = state {
            redirectString += "&state=\(state)"
        }

        return req.redirect(to: redirectURI)
    }
}

struct AuthorizationGetRequestObject {
    let clientID: String
    let redirectURIString: String
    let scopes: [String]
    let state: String?
    let responseType: String
}
