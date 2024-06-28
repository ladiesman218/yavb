import Vapor

struct BrevoSMSContent: BrevoMessage {
    typealias Sender = String
    typealias Recipient = String
    
    static var sender: String = Environment.get("BREVO_SENDER_NAME") ?? "noreply"
    
    var recipient: String
    var subject: String? = nil
    var content: String
    
    enum CodingKeys: String, CodingKey {
        case sender = "sender"
        case recipient = "recipient"
        case content = "content"
    }
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(Self.sender, forKey: .sender)
        try container.encode(recipient, forKey: .recipient)
        try container.encode(content, forKey: .content)
    }
    
    init(recipient: String, subject: String? = nil, content: String) {
        self.recipient = recipient
        self.subject = subject
        self.content = content
    }
}

struct BrevoSMS: Content {
    static let endpoint = URI(string: "https://api.brevo.com/v3/transactionalSMS/sms")
    static let headers: HTTPHeaders = {
        var headers = HTTPHeaders()
        headers.replaceOrAdd(name: .accept, value: "application/json")
        headers.replaceOrAdd(name: .contentType, value: "application/json")
        headers.replaceOrAdd(name: "api-key", value: Environment.get("BREVOAPI")!)
        return headers
    }()
    
    let content: BrevoSMSContent
    
    func send(request: Request) async throws -> ClientResponse {
        return try await request.client.post(Self.endpoint, headers: Self.headers, content: content)
    }
}

extension Request {
    func sendSMS(_ sms: BrevoSMS) async throws -> ClientResponse {
        return try await sms.send(request: self)
    }
}
