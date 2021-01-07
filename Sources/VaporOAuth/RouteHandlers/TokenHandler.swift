 import Vapor

 struct TokenHandler {

     let tokenAuthenticator = TokenAuthenticator()
     let refreshTokenHandler: RefreshTokenHandler
     let clientCredentialsTokenHandler: ClientCredentialsTokenHandler
     let tokenResponseGenerator: TokenResponseGenerator
     let authCodeTokenHandler: AuthCodeTokenHandler
     let passwordTokenHandler: PasswordTokenHandler

     init(clientValidator: ClientValidator, tokenManager: TokenManager, scopeValidator: ScopeValidator,
          codeManager: CodeManager, userManager: UserManager, log: Logger) {
         tokenResponseGenerator = TokenResponseGenerator()
         refreshTokenHandler = RefreshTokenHandler(scopeValidator: scopeValidator, tokenManager: tokenManager,
                                                   clientValidator: clientValidator, tokenAuthenticator: tokenAuthenticator,
                                                   tokenResponseGenerator: tokenResponseGenerator)
         clientCredentialsTokenHandler = ClientCredentialsTokenHandler(clientValidator: clientValidator,
                                                                       scopeValidator: scopeValidator,
                                                                       tokenManager: tokenManager,
                                                                       tokenResponseGenerator: tokenResponseGenerator)
         authCodeTokenHandler = AuthCodeTokenHandler(clientValidator: clientValidator, tokenManager: tokenManager,
                                                     codeManager: codeManager,
                                                     tokenResponseGenerator: tokenResponseGenerator)
         passwordTokenHandler = PasswordTokenHandler(clientValidator: clientValidator, scopeValidator: scopeValidator,
                                                     userManager: userManager, log: log, tokenManager: tokenManager,
                                                     tokenResponseGenerator: tokenResponseGenerator)
     }

     func handleRequest(_ req: Request) throws -> EventLoopFuture<Response> {
         guard let grantType: String = req.query[OAuthRequestParameters.grantType] else {
             return try tokenResponseGenerator.createResponse(req, error: OAuthResponseParameters.ErrorType.invalidRequest,
                                                              description: "Request was missing the 'grant_type' parameter")
         }

         switch grantType {
         case OAuthFlowType.authorization.rawValue:
             return try authCodeTokenHandler.handleAuthCodeTokenRequest(req)
         case OAuthFlowType.password.rawValue:
             return try passwordTokenHandler.handlePasswordTokenRequest(req)
         case OAuthFlowType.clientCredentials.rawValue:
             return try clientCredentialsTokenHandler.handleClientCredentialsTokenRequest(req)
         case OAuthFlowType.refresh.rawValue:
             return try refreshTokenHandler.handleRefreshTokenRequest(req)
         default:
             return try tokenResponseGenerator.createResponse(req, error: OAuthResponseParameters.ErrorType.unsupportedGrant,
                                                              description: "This server does not support the '\(grantType)' grant type")
         }

     }

 }
