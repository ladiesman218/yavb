import Vapor

extension Message {
    struct Recipient: Encodable, Hashable {
        static let phoneRegex = "^(\\+[1-9]+(-?[0-9]+))?[- ]?([0-9\\- ]+)[0-9]$"
        static let emailRegex = "^(?:[a-zA-Z0-9!#$%\\&‘*+/=?\\^_`{|}~-]+(?:\\.[a-zA-Z0-9!#$%\\&'*+/=?\\^_`{|}~-]+)*|\"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*\")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\\[(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21-\\x5a\\x53-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)\\])$"

        enum ContactType {
            case sms, email
        }
        
        enum CodingKeys: CodingKey {
            case name
            case email
            case phone
        }
        
        func encode(to encoder: any Encoder) throws {
            var validations = Validations()

            var container = encoder.container(keyedBy: Recipient.CodingKeys.self)
            switch self.contactType {
                case .sms:
                    try container.encode(contactInfo, forKey: CodingKeys.phone)
                case .email:
                    try container.encodeIfPresent(name, forKey: CodingKeys.name)
                    try container.encode(contactInfo, forKey: CodingKeys.email)
            }
        }
        
        let name: String?
        let contactInfo: String
        let contactType: ContactType
        
        init(name: String?, contactInfo: String) throws {
            if contactInfo.contains(try! Regex(Self.emailRegex)) {
                self.contactType = .email
            } else if contactInfo.contains(try! Regex(Self.phoneRegex)) {
                self.contactType = .sms
            } else {
                let error = Abort(.badRequest, reason: "Invalid contact info")
                let logger = Logger(label: "top.mleak.message")
                logger.error("\(error)")
                throw Abort(.badRequest, reason: "Invalid contact info")
            }
            self.name = name
            self.contactInfo = contactInfo
        }
    }
}

struct Message: Encodable {
    static let placeHolder = "${placeHolder}"
    static let sender = try! Recipient(name: "noreply", contactInfo: "noreply@mleak.top")
    
    let recipients: Set<Recipient>
    let subject: String
    let body: String
    init(to: Set<Recipient>, placeHolders: [String], template: String, subject: String) throws {
        guard !template.isEmpty else {
            let error = Abort(.badRequest, reason: "Message template can not be empty")
            throw error
        }
        // Make sure number of placeholders are identical in both array and template
        guard placeHolders.count == template.countOccurrences(of: Self.placeHolder) else {
            let error = Abort(.badRequest, reason: "Number of placeholders doesn't match")
            throw error
        }
        var messageString = template
        self.subject = subject
        self.recipients = to
        placeHolders.forEach {
            messageString = messageString.replacing(Self.placeHolder, with: $0)
        }
        self.body = messageString
    }
    
    func send(client: Client) {
        do {
            // Brevo requires String type for content parameter. CustomStringConvertible protocol gives a description variable, but that makes working with multi-line strings harder. So here we convert self to json data, then convert that data back to string again...
            let data = try JSONEncoder().encode(self)
            guard let string = String(data: data, encoding: .utf8) else {
                throw Abort(.badRequest, reason: "Unable to convert email data to string: \(self)")
            }
            
            // No need to wait for the response
            Task {
                // According to documentation, https://developers.brevo.com/reference/sendtransacemail, response's status will be 201 when email sent, or 202 when email is scheduled, or 400 when failed
                let response = try await client.post(Brevo.endpoint, headers: Brevo.messageHTTPHeaders, content: string)
                guard response.status.code < 300 && response.status.code >= 200 else {
                    //                    Self.alertAdmin(error: MessageError.unableToSend(response: response), client: client)
                    print(response)
                    return
                }
            }
        } catch {
            print(error)
            //            Self.alertAdmin(error: error, client: client)
        }
    }
}

