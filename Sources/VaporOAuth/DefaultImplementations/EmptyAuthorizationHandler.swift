import Vapor

public struct EmptyAuthorizationHandler: AuthorizeHandler {

    public init() {}

    public func handleAuthorizationError(_ errorType: AuthorizationError) throws -> Response {
        return Response()
    }

    public func handleAuthorizationRequest(_ req: Request,
                                           authorizationRequestObject: AuthorizationRequestObject) throws -> String {
        return ""
    }
}
