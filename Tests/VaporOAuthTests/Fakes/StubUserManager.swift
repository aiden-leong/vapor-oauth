import VaporOAuth
import Node

struct StubUserManager: UserManager {
    func authenticateUser(username: String, password: String) -> UUID? {
        return nil
    }
    
    func getUser(userID: UUID) -> OAuthUser? {
        return nil
    }
}
