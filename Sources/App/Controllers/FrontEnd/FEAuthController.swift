import Vapor
import JWTKit

struct FrontendAuthController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let auth = routes.grouped("auth")
        auth.get("activate", ":jwt", use: activate)
        auth.get("changePW", ":jwt", use: changePW)
    }
    
    func activate(_ req: Request) async throws -> Response {
        var js = "const blogList = document.querySelectorAll('.list-unstyled')[0];"
        do {
            try await AuthController().activate(req)
            let message = "Activation success. You have been logged in automatically."
            js += "appendAlert(blogList, '\(message)', 'success');"
            return try await PublicFEController.renderHome(req, js: js).encodeResponse(for: req)
        } catch {
            // If error happens when verifying jwt, then check if it's expiration first.
            if error is JWTError {
                if let jwt = req.parameters.get("jwt"),
                   let data = jwt.data(using: .utf8),
                   let token = try? DefaultJWTParser().parse(data, as: UserJWT.self),
                   token.payload.subject == UserJWT.Subject.activation,
                   let idString = token.payload.audience.value.first,
                   let userID = UUID(uuidString: idString),
                   let user = try await User.find(userID, on: req.db) {
                    let errorMessage = "Link expired. Try <button id=\\'resendActivation\\' class=\\'btn btn-warning\\' onclick=\\'requestActivation(\"\(user.email)\")\\'>request a new activation link</button> and make sure to use it in \(jwtValidMinutes) minutes"
                    js += "appendAlert(blogList, '\(errorMessage)', 'danger');"
                    return try await PublicFEController.renderHome(req, js: js).encodeResponse(for: req)
                } else {
                    // Here means the jwt is wrong
                    let errorMessage = "Invalid link. Make sure you did not miss any character when copy/pasting."
                    js += "appendAlert(blogList, '\(errorMessage)', 'danger');"
                    return try await PublicFEController.renderHome(req, js: js).encodeResponse(for: req)
                }
                
            }
            // Here means it's not a jwt verifying error, then show the error message itself.
            let errorMessage = error.localizedDescription
            js += "appendAlert(blogList, '\(errorMessage)', 'danger');"
            return try await PublicFEController.renderHome(req, js: js).encodeResponse(for: req)
        }
    }
    
    func changePW(_ req: Request) async throws -> View {
        // In request.render extension, jwt is already retrieved from request parameter, but there it's optinal. Here we just make sure it exists.
        guard req.parameters.get("jwt") != nil else { throw Abort(.badRequest) }
        // Make sure modal for typing in new passwords is opened.
        let js = """
        const newPWModal = new bootstrap.Modal(document.getElementById(setNewPasswordModalID));
        newPWModal.show();
"""
        return try await PublicFEController.renderHome(req, js: js)
    }
}
