import Node

public protocol CodeManager {
    func generateCode(userID: Identifier, clientID: String, redirectURI: String, scopes: [String]?) throws -> String
    func getCode(_ code: String) -> OAuthCode?
    
    // This is explicit to ensure that the code is marked as used or deleted (it could be implied that this is done when you call
    // `getCode` but it is called explicitly to remind developers to ensure that codes can't be reused)
    func codeUsed(_ code: OAuthCode)
}
