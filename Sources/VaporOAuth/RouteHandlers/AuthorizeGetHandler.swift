import Vapor

struct AuthorizeGetHandler {

    let authorizeHandler: AuthorizeHandler
    let clientValidator: ClientValidator

    func handleRequest(request: Request) throws -> Response {

        let (errorResponse, createdAuthRequestObject) = try validateRequest(request)

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
            let x = try authorizeHandler.handleAuthorizationError(.invalidClientID) 
            return try authorizeHandler.handleAuthorizationError(.invalidClientID)
        } catch AuthorizationError.invalidRedirectURI {
            return try authorizeHandler.handleAuthorizationError(.invalidRedirectURI)
        } catch ScopeError.unknown {
            return createErrorResponse(
                    request: request,
                    redirectURI: authRequestObject.redirectURIString,
                    errorType: OAuthResponseParameters.ErrorType.invalidScope,
                    errorDescription: "scope+is+unknown",
                    state: authRequestObject.state
            )
        } catch ScopeError.invalid {
            return createErrorResponse(
                    request: request,
                    redirectURI: authRequestObject.redirectURIString,
                    errorType: OAuthResponseParameters.ErrorType.invalidScope,
                    errorDescription: "scope+is+invalid",
                    state: authRequestObject.state
            )
        } catch AuthorizationError.confidentialClientTokenGrant {
            return createErrorResponse(
                    request: request,
                    redirectURI: authRequestObject.redirectURIString,
                    errorType: OAuthResponseParameters.ErrorType.unauthorizedClient,
                    errorDescription: "token+grant+disabled+for+confidential+clients",
                    state: authRequestObject.state
            )
        } catch AuthorizationError.httpRedirectURI {
            return try authorizeHandler.handleAuthorizationError(.httpRedirectURI)
        }

        let redirectURI = URIParser.shared.parse(bytes: authRequestObject.redirectURIString.makeBytes())
        let csrfToken = try Random.bytes(count: 32).hexString

        guard let session = request.session else {
            throw Abort(.badRequest)
        }

        try session.data.set(SessionData.csrfToken, csrfToken)
        let authorizationRequestObject = AuthorizationRequestObject(responseType: authRequestObject.responseType,
                clientID: authRequestObject.clientID, redirectURI: redirectURI,
                scope: authRequestObject.scopes, state: authRequestObject.state,
                csrfToken: csrfToken)

        return try authorizeHandler.handleAuthorizationRequest(request, authorizationRequestObject: authorizationRequestObject)
    }

    private func validateRequest(_ request: Request) throws -> (Response?, AuthorizationGetRequestObject?) {
        guard let clientID: String = request.query[OAuthRequestParameters.clientID] else {
            return (try authorizeHandler.handleAuthorizationError(.invalidClientID), nil)
        }

        guard let redirectURIString: String = request.query[OAuthRequestParameters.redirectURI] else {
            return (try authorizeHandler.handleAuthorizationError(.invalidRedirectURI), nil)
        }

        let scopes: [String]

        if let scopeQuery: String = request.query[OAuthRequestParameters.scope] {
            scopes = scopeQuery.components(separatedBy: " ")
        } else {
            scopes = []
        }

        let state: String = request.query[OAuthRequestParameters.state]

        guard let responseType: String = request.query[OAuthRequestParameters.responseType] else {
            let errorResponse = createErrorResponse(
                    request: request,
                    redirectURI: redirectURIString,
                    errorType: OAuthResponseParameters.ErrorType.invalidRequest,
                    errorDescription: "Request+was+missing+the+response_type+parameter",
                    state: state
            )
            return (errorResponse, nil)
        }

        guard responseType == ResponseType.code || responseType == ResponseType.token else {
            let errorResponse = createErrorResponse(
                    request: request,
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

    private func createErrorResponse(request: Request, redirectURI: String, errorType: String, errorDescription: String,
                                     state: String?) -> Response {
        var redirectString = "\(redirectURI)?error=\(errorType)&error_description=\(errorDescription)"

        if let state = state {
            redirectString += "&state=\(state)"
        }

        return request.redirect(to: redirectURI)
    }
}

struct AuthorizationGetRequestObject {
    let clientID: String
    let redirectURIString: String
    let scopes: [String]
    let state: String?
    let responseType: String
}
