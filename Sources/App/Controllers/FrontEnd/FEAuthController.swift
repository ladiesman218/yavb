import Vapor

struct FrontendAuthController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let auth = routes.grouped("auth")
        auth.get("activate", ":jwt", use: activate)
        auth.get("changePW", ":jwt", use: changePW)
        auth.post("login", use: login)
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
    
    /// Frontend needs a redirect path to decide if login success, where to go next. Here we default the redirect path to home page("/") but add the ability to modify it. By adding a "next" query item in url when making the request, like "http://localhost:8082/?next=/manage", success login will take users to the given "next" path. Adding query items do not need extra endpoints and will not cause error for exising ones, route handlers can choose to ignore them completely. But here we check if it has an "next" value. By default frontend manage controller will redirect to "/?login=1&next=\(req.url.path)" if a valid session cookie is not found in request.
    func login(_ req: Request) async throws -> Response {
        let _ = try await AuthController().login(req)
        // Init a header for response
        var headers = HTTPHeaders()
        
        // Get request header, see if there is a "Referer" field in it.
        if let string = req.headers["Referer"].first,
           let url = URL(string: string),
           let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let queryItems = components.queryItems,
           let nextItem = queryItems.first(where: { $0.name == "next" }),
           let nextValue = nextItem.value
        {
            // Pass the request's referer to response
            headers.replaceOrAdd(name: .referer, value: nextValue)
        } else {
            headers.replaceOrAdd(name: .referer, value: "/")
        }
           
        return .init(status: .ok, headers: headers)
    }
}
