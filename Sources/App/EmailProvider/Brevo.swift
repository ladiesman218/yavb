import Vapor

enum Brevo {
    
    static let endpoint = URI(string: "https://api.brevo.com/v3/smtp/email")
    static let messageHTTPHeaders: HTTPHeaders = {
        var headers = HTTPHeaders()
        headers.replaceOrAdd(name: .accept, value: "application/json")
        headers.replaceOrAdd(name: .contentType, value: "application/json")
        headers.replaceOrAdd(name: "api-key", value: Environment.get("BREVOAPI")!)
        return headers
    }()
//    static func send(to: [String], content: String, req: Request) async throws -> ClientResponse {
//        return try await req.client.post(Self.endpoint, content: "")
//    }
    
    
    
}

