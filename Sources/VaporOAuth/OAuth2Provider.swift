import Vapor

struct OAuth2Provider {

    let tokenManager: TokenManager
    let userManager: UserManager
    let authorizePostHandler: AuthorizePostHandler
    let authorizeGetHandler: AuthorizeGetHandler
    let tokenHandler: TokenHandler
    let tokenIntrospectionHandler: TokenIntrospectionHandler
    let resourceServerAuthenticator: ResourceServerAuthenticator

    init(codeManager: CodeManager, tokenManager: TokenManager, clientRetriever: ClientRetriever,
         authorizeHandler: AuthorizeHandler, userManager: UserManager, validScopes: [String]?,
         resourceServerRetriever: ResourceServerRetriever, environment: Environment, log: Logger) {
        self.tokenManager = tokenManager
        self.userManager = userManager

        resourceServerAuthenticator = ResourceServerAuthenticator(resourceServerRetriever: resourceServerRetriever)
        let scopeValidator = ScopeValidator(validScopes: validScopes, clientRetriever: clientRetriever)
        let clientValidator = ClientValidator(clientRetriever: clientRetriever, scopeValidator: scopeValidator, environment: environment)
        authorizePostHandler = AuthorizePostHandler(tokenManager: tokenManager, codeManager: codeManager, clientValidator: clientValidator)
        authorizeGetHandler = AuthorizeGetHandler(authorizeHandler: authorizeHandler, clientValidator: clientValidator)
        tokenHandler = TokenHandler(clientValidator: clientValidator, tokenManager: tokenManager, scopeValidator: scopeValidator,
                                    codeManager: codeManager, userManager: userManager, log: log)
        tokenIntrospectionHandler = TokenIntrospectionHandler(clientValidator: clientValidator, tokenManager: tokenManager,
                                                              userManager: userManager)
    }

    func addRoutes(to app: Application) {
        app.get("oauth/authorize", use: authorizeGetHandler.handleRequest)
        app.post("oauth/authorize", use: authorizePostHandler.handleRequest)
        app.post("oauth/token", use: tokenHandler.handleRequest)

        let tokenIntrospectionAuthMiddleware = TokenIntrospectionAuthMiddleware(resourceServerAuthenticator: resourceServerAuthenticator)
        let resourceServerProtected = app.grouped(tokenIntrospectionAuthMiddleware)
        resourceServerProtected.post("oauth/token_info", use: tokenIntrospectionHandler.handleRequest)
    }

}
