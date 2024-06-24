import Vapor

struct FrontendAuthController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let auth = routes.grouped("auth")
        auth.get("activate", ":jwt", use: activate)
        auth.get("changePW", ":jwt", use: changePW)
    }
    
    func activate(_ req: Request) async throws -> Response {
        try await AuthController().activate(req)
        return req.redirect(to: "/")
    }
    
    func changePW(_ req: Request) async throws -> View {
        guard let jwt = req.parameters.get("jwt") else { throw Abort(.badRequest) }
        // Make sure modal for typing in new passwords is opened.
        let js = """
        const newPWModal = new bootstrap.Modal(document.getElementById(setNewPasswordModalID));
        newPWModal.show();
"""
        return try await PublicFEController.renderHome(req, js: js, jwt: jwt)
    }
}
