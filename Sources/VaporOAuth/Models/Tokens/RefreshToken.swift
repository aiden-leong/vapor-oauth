import Vapor

public final class RefreshToken: Extendable {
    public let tokenString: String
    public let clientID: String
    public let userID: UUID?
    public var scopes: [String]?

    public var extend = Extend()

    public init(tokenString: String, clientID: String, userID: UUID?, scopes: [String]? = nil) {
        self.tokenString = tokenString
        self.clientID = clientID
        self.userID = userID
        self.scopes = scopes
    }
}
