 import Vapor

 struct OAuthResponse: Codable {
     var error: String?
     var errorDescription: String?
     var active: Bool?
     var clientID: String?
     var scopes: String?
     var userID: UUID?
     var username: String?
     var email: String?
     var exp: Int?
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
             oauthResponse.clientID = clientID
         }

         if let scopes = scopes {
             oauthResponse.scopes = scopes
         }

         if let user = user {
             oauthResponse.userID = user.id
             oauthResponse.username = user.username
             if let email = user.emailAddress {
                 oauthResponse.email = email
             }
         }

         if let expiryDate = expiryDate {
             oauthResponse.exp = Int(expiryDate.timeIntervalSince1970)
         }

         let encoder = JSONEncoder.init()
         let bodyData = try encoder.encode(oauthResponse)
         let bodyString = String(data: bodyData, encoding: .utf8)!
         let httpHeaders = HTTPHeaders()
         let response = Response(status: .ok, version: .init(major: 1, minor: 1), headers: httpHeaders, body: .init(string: bodyString))

         return response
     }

     func createErrorResponse(status: HTTPStatus, errorMessage: String, errorDescription: String) throws -> Response {
         let oauthResponse = OAuthResponse(error: errorMessage, errorDescription: errorDescription)

         let encoder = JSONEncoder.init()
         let bodyData = try encoder.encode(oauthResponse)
         let bodyString = String(data: bodyData, encoding: .utf8)!
         let httpHeaders = HTTPHeaders()
         let response = Response(status: .ok, version: .init(major: 1, minor: 1), headers: httpHeaders, body: .init(string: bodyString))

         return response
     }
 }
