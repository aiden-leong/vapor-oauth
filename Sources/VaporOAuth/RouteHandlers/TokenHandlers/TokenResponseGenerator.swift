import Vapor

struct TokenResponse: Codable {
    var error: String?
    var errorDescription: String?
    var tokenType: String?
    var expiresIn: Int?
    var accessToken: String?
    var refreshToken: String?
    var scope: String?
}

struct TokenResponseGenerator {
    func createResponse(error: String, description: String, status: HTTPStatus = .badRequest) throws -> EventLoopFuture<Response> {
        let tokenResponse = TokenResponse(error: error, errorDescription: description)

        return try createResponseForToken(status: status, tokenResponse: tokenResponse)
    }

    func createResponse(accessToken: AccessToken, refreshToken: RefreshToken?,
                        expiresIn: Int, scope: String?) throws -> EventLoopFuture<Response> {

        var tokenResponse = TokenResponse(tokenType: "bearer", expiresIn: expiresIn, accessToken: accessToken.tokenString)

        if let refreshToken = refreshToken {
            tokenResponse.refreshToken = refreshToken.tokenString
        }

        if let scope = scope {
            tokenResponse.scope = scope
        }

        return try createResponseForToken(status: .ok, tokenResponse: tokenResponse)
    }

    private func createResponseForToken(status: HTTPStatus, tokenResponse: TokenResponse) throws -> EventLoopFuture<Response> {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try! encoder.encode(tokenResponse)
        let jsonString = String(data: data, encoding: .utf8)!

        let response = Response(status: status, body: .init(string: jsonString))

        response.headers.add(name: "Pragma", value: "no-cache")
        response.headers.add(name: "Cache-Control", value: "no-store")

        return response
    }

}
