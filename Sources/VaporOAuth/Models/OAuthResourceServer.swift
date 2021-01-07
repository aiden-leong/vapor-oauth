import Vapor

public final class OAuthResourceServer: Extendable {
    public let username: String
    public let password: [UInt8]
    public var extend = Extend()

    public init(username: String, password: [UInt8]) {
        self.username = username
        self.password = password
    }
}
