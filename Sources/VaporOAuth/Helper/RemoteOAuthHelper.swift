 import Vapor

 class RemoteOAuthHelper: OAuthHelper {

     weak var req: Request?
     let tokenIntrospectionEndpoint: String
     let client: Client
     let resourceServerUsername: String
     let resourceServerPassword: String
     var remoteTokenResponse: RemoteTokenResponse?

     init(req: Request, tokenIntrospectionEndpoint: String, client: Client,
          resourceServerUsername: String, resourceServerPassword: String) {
         self.req = req
         self.tokenIntrospectionEndpoint = tokenIntrospectionEndpoint
         self.client = client
         self.resourceServerUsername = resourceServerUsername
         self.resourceServerPassword = resourceServerPassword
         self.remoteTokenResponse = nil
     }

     func assertScopes(_ req: Request, scopes: [String]?) -> EventLoopFuture<Void> {
         return setupRemoteTokenResponse(req)
            .flatMap { [self] in
                guard let remoteTokenResponse = remoteTokenResponse else {
                    return req.eventLoop.makeFailedFuture(Abort(.internalServerError))
                }

                if let requiredScopes = scopes {
                    guard let tokenScopes = remoteTokenResponse.scopes else {
                        return req.eventLoop.makeFailedFuture(Abort(.unauthorized))
                    }

                    for scope in requiredScopes {
                        if !tokenScopes.contains(scope) {
                            return req.eventLoop.makeFailedFuture(Abort(.unauthorized))
                        }
                    }
                }
                return req.eventLoop.future()
            }
     }

     func user(_ req: Request) -> EventLoopFuture<OAuthUser> {
//         if remoteTokenResponse == nil {
//             setupRemoteTokenResponse(req)
//         }

        return setupRemoteTokenResponse(req)
            .flatMap { [self] in
                guard let remoteTokenResponse = remoteTokenResponse else {
                    return req.eventLoop.makeFailedFuture(Abort(.internalServerError))
                }

                guard let user = remoteTokenResponse.user else {
                    return req.eventLoop.makeFailedFuture(Abort(.unauthorized))
                }

                return req.eventLoop.future(user)
            }
     }

     struct TokenInfoResponse: Content {
         var active: Bool?
         var scope: String?
         var userID: String?
         var username: String?
         var email: String?
     }

     private func setupRemoteTokenResponse(_ req: Request) -> EventLoopFuture<Void> {
         return req.getOAuthToken(req)
             .flatMap { [self] token in
                 req.client.post(URI(string: tokenIntrospectionEndpoint)) { req in
                     // Encode JSON to the request body.
                     try req.content.encode(["token": token])
                     let resourceAuthHeader = Data("\(resourceServerUsername):\(resourceServerPassword)".utf8).base64EncodedString()
                     req.headers.add(name: "authorization", value: "Basic \(resourceAuthHeader)")
                 }
             }
             .flatMap { res -> EventLoopFuture<TokenInfoResponse> in
                do {
                    return try req.eventLoop.future(res.content.decode(TokenInfoResponse.self))
                } catch {
                    return req.eventLoop.makeFailedFuture(Abort(.internalServerError))
                }
             }
             .flatMap { [self] json -> EventLoopFuture<Void> in
                 // Handle the json response.
                 guard let tokenActive = json.active, tokenActive else {
                     return req.eventLoop.makeFailedFuture(Abort(.unauthorized))
                 }
                 var scopes: [String]?
                 if let tokenScopes = json.scope {
                     scopes = tokenScopes.components(separatedBy: " ")
                 }

                 var oauthUser: OAuthUser?
                 if let userID = json.userID {
                     guard let username = json.username else {
                         return req.eventLoop.makeFailedFuture(Abort(.internalServerError))
                     }
                     let userIdentifier = UUID(userID)
                     oauthUser = OAuthUser(userID: userIdentifier, username: username,
                             emailAddress: json.email,
                             password: [0])
                 }
                 remoteTokenResponse = RemoteTokenResponse(scopes: scopes, user: oauthUser)
                 return req.eventLoop.future()
             }
     }
 }

 struct RemoteTokenResponse {
     let scopes: [String]?
     let user: OAuthUser?
 }
