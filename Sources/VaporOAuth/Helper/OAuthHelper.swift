import Vapor

protocol OAuthHelper {
    func assertScopes(_ req: Request, scopes: [String]?) -> EventLoopFuture<Void>
    func user(_ req: Request) throws -> EventLoopFuture<OAuthUser>
}
