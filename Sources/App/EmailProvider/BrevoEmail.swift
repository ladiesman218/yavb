import Vapor

struct BrevoEmailContent: BrevoMessage {
    typealias Sender = Dictionary<String, String>
    typealias Recipient = [Dictionary<String, String>]
    static let sender = ["name": Environment.get("BREVO_SENDER_NAME") ?? "noreply", "email": Environment.get("BREVO_SENDER_EMAIL") ?? "noreply@test.com"]
    
    let subject: String?
    let content: String
    let recipient: Recipient
    
    enum CodingKeys: String, CodingKey, CaseIterable {
        case sender = "sender"
        case subject = "subject"
        case recipient = "to"
        case content = "htmlContent"
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(Self.sender, forKey: .sender)
        try container.encode(subject, forKey: .subject)
        try container.encode(recipient, forKey: .recipient)
        try container.encode(content, forKey: .content)
    }
    
    init(subject: String, recipient: [Dictionary<String, String>], htmlContent: String) {
        self.subject = subject
        self.recipient = recipient
        self.content = htmlContent
    }
}

struct BrevoEmail: Content {
    static let endpoint = URI(string: "https://api.brevo.com/v3/smtp/email")
    static let headers: HTTPHeaders = {
        var headers = HTTPHeaders()
        headers.replaceOrAdd(name: .accept, value: "application/json")
        headers.replaceOrAdd(name: .contentType, value: "application/json")
        headers.replaceOrAdd(name: "api-key", value: Environment.get("BREVOAPI")!)
        return headers
    }()
    
    
    let emailContent: BrevoEmailContent
    
    func send(request: Request) async throws -> ClientResponse {
        return try await request.client.post(Self.endpoint, headers: Self.headers, content: emailContent)
    }
}

extension Request {
    func sendMail(_ mail: BrevoEmail) async throws -> ClientResponse {
        return try await mail.send(request: self)
    }
}

