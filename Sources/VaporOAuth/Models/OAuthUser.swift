import Vapor

public final class OAuthUser: Authenticatable, Extendable {
    public let username: String
    public let emailAddress: String?
    public var password: [UInt8]
    // swiftlint:disable:next identifier_name
    public var id: UUID?

    public var extend = Extend()

    public init(userID: UUID? = nil, username: String, emailAddress: String?, password: [UInt8]) {
        self.username = username
        self.emailAddress = emailAddress
        self.password = password
        self.id = userID
    }
}
