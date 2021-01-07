import Vapor

public struct EmptyUserManager: UserManager {

    public init() {}

    public func getUser(userID: UUID) -> OAuthUser? {
        return nil
    }

    public func authenticateUser(username: String, password: String) -> UUID? {
        return nil
    }
}
