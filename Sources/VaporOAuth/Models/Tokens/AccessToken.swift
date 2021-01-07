import Vapor

public final class AccessToken: Extendable {
    public let tokenString: String
    public let clientID: String
    public let userID: UUID?
    public let scopes: [String]?
    public let expiryTime: Date

    public var extend = Extend()

    public init(tokenString: String, clientID: String, userID: UUID?, scopes: [String]? = nil, expiryTime: Date) {
        self.tokenString = tokenString
        self.clientID = clientID
        self.userID = userID
        self.scopes = scopes
        self.expiryTime = expiryTime
    }
}
