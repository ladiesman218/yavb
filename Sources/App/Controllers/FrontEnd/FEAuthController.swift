import Vapor

struct FrontendAuthController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let auth = routes.grouped("auth")
        auth.get("activate", ":jwt", use: activate)
        auth.get("changePW", ":jwt", use: changePW)
        // Only to trigger the displaying of login modal. DO NOT use it directly.
        auth.get("login", use: reLogin)
    }
    
    func activate(_ req: Request) async throws -> Response {
        try await AuthController().activate(req)
        return req.redirect(to: "/")
    }
    
    func changePW(_ req: Request) async throws -> View {
        guard let jwt = req.parameters.get("jwt") else { throw Abort(.unauthorized) }
        // Make sure modal for type in new passwords is opened.
        let js = """
        const newPWModal = new bootstrap.Modal(document.getElementById(setNewPasswordModalID));
        newPWModal.show();
"""
        return try await req.view.render("main", ["script": js, "jwt": jwt])
    }
    
    // Essentially render the home page again, with custom js to pop up the login modal.
    func reLogin(_ req: Request) async throws -> View {
        let js = """
deleteCookie('yavb-session');
// Trigger header shows the login and register button other than the manage link.
getLoginStatus();
// Set url to home address, currently it's /auth/login. We are handling successful login response by reloading, so without this, get /auth/login again triggers the remove of cookie again.
window.location.replace('/');
// Call out the login modal.
const loginModal = new bootstrap.Modal(document.querySelector('#loginModal'));
loginModal.show();
"""
        return try await PublicFEController.renderHome(req, js: js)
    }
}
