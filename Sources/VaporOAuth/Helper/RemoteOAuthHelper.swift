// import Vapor

// class RemoteOAuthHelper: OAuthHelper {

//     weak var req: Request?
//     let tokenIntrospectionEndpoint: String
//     let client: Client
//     let resourceServerUsername: String
//     let resourceServerPassword: String
//     var remoteTokenResponse: RemoteTokenResponse?

//     init(req: Request, tokenIntrospectionEndpoint: String, client: Client,
//          resourceServerUsername: String, resourceServerPassword: String) {
//         self.req = req
//         self.tokenIntrospectionEndpoint = tokenIntrospectionEndpoint
//         self.client = client
//         self.resourceServerUsername = resourceServerUsername
//         self.resourceServerPassword = resourceServerPassword
//         self.remoteTokenResponse = nil
//     }

//     func assertScopes(_ req: Request, scopes: [String]?) -> EventLoopFuture<Void> {
//         return setupRemoteTokenResponse(req)

//         guard let remoteTokenResponse = remoteTokenResponse else {
//             return req.eventLoop.makeFailedFuture(Abort(.internalServerError))
//         }

//         if let requiredScopes = scopes {
//             guard let tokenScopes = remoteTokenResponse.scopes else {
//                 return req.eventLoop.makeFailedFuture(Abort(.unauthorized))
//             }

//             for scope in requiredScopes {
//                 if !tokenScopes.contains(scope) {
//                     return req.eventLoop.makeFailedFuture(Abort(.unauthorized))
//                 }
//             }
//         }

//     }

//     func user(_ req: Request) -> EventLoopFuture<OAuthUser> {
//         if remoteTokenResponse == nil {
//             setupRemoteTokenResponse(req)
//         }

//         guard let remoteTokenResponse = remoteTokenResponse else {
//             return req.eventLoop.makeFailedFuture(Abort(.internalServerError))
//         }

//         guard let user = remoteTokenResponse.user else {
//             return req.eventLoop.makeFailedFuture(Abort(.unauthorized))
//         }

//         return req.eventLoop.future(user)
//     }

//     struct TokenRequest {
//         var token: String
//     }

//     private func setupRemoteTokenResponse(_ req: Request) -> EventLoopFuture<Void> {
//         return req.getOAuthToken(req)
//             .flatMap { token in
//                 let tokenRequest = Request(application: req.application, method: .post, url: tokenIntrospectionEndpoint, on: req.eventLoop)
//                 var tokenRequestJSON = JSON()
//                 try tokenRequestJSON.set("token", token)
//                 tokenRequest.json = tokenRequestJSON


//                 let resourceAuthHeader = "\(resourceServerUsername):\(resourceServerPassword)".makeBytes().base64Encoded.makeString()
//                 tokenRequest.headers[.authorization] = "Basic \(resourceAuthHeader)"

//                 let tokenInfoResponse = try client.respond(to: tokenRequest)
// //        client.post(URI(string: tokenIntrospectionEndpoint)) {
// //            req in
// //
// //        }
//             }

//         guard let tokenInfoJSON = tokenInfoResponse.json else {
//             req.eventLoop.makeFailedFuture(Abort(.internalServerError))
//         }

//         guard let tokenActive = tokenInfoJSON[OAuthResponseParameters.active]?.bool, tokenActive else {
//             req.eventLoop.makeFailedFuture(Abort(.unauthorized))
//         }

//         var scopes: [String]?
//         var oauthUser: OAuthUser?

//         if let tokenScopes = tokenInfoJSON[OAuthResponseParameters.scope] {
//             scopes = tokenScopes.components(separatedBy: " ")
//         }

//         if let userID = tokenInfoJSON[OAuthResponseParameters.userID] {
//             guard let username = tokenInfoJSON[OAuthResponseParameters.username] else {
//                 req.eventLoop.makeFailedFuture(Abort(.internalServerError))
//             }
//             let userIdentifier: UUID = UUID(userID, in: nil)
//             oauthUser = OAuthUser(userID: userIdentifier, username: username,
//                     emailAddress: tokenInfoJSON[OAuthResponseParameters.email],
//                     password: "".makeBytes())
//         }

//         self.remoteTokenResponse = RemoteTokenResponse(scopes: scopes, user: oauthUser)

//     }
// }

// struct RemoteTokenResponse {
//     let scopes: [String]?
//     let user: OAuthUser?
// }
