import Vapor


struct Body: Encodable {
    static let placeHolder = "${placeHolder}"
    let string: String
    init(placeHolders: [String], template: String, subject: String) throws {
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
        placeHolders.forEach {
            messageString = messageString.replacing(Self.placeHolder, with: $0)
        }
        self.string = messageString
    }
    func send(to recipient: some MessageReceivable) throws {
        try recipient.send()
    }
}


enum MessageType: Hashable, Encodable {
    case email(address: String)
    case sms(number: String)
    indirect case multiple(options: Set<Self>)
//    func encode(to encoder: any Encoder) throws {
//        var container = encoder.singleValueContainer()
//        switch self {
//            case .email(let address):
//                try container.encode(address)
//            case .sms(let number):
//                try container.encode(number)
//            case .multiple(let options):
//                try container.encode("")
//        }
//    }
    func send(message: Body) throws {
    }
}


protocol MessageReceivable: Encodable {
    var name: String? { get }
    var type: MessageType { get }
    func send() throws
}
extension MessageReceivable {
    func send() throws {
        switch type {
            case .email(let address):
                try Email.send()
            case .sms(number: let number):
                try SMS.send()
            case .multiple(let options):
                break
        }
    }
}
struct Recipient: Encodable {
    var name: String? = nil
    var type: MessageType
}
struct Email {
    static let sender = Recipient(name: "noreply", type: .email(address: "noreply@mleak.top"))
    var recipient: Recipient
    var message: Body
    static func send() throws {
        
    }
}
struct SMS {
    var recipient: Recipient
    var message: Body
    static func send() throws {
        
    }
}
//    message.send(to: recipient)
func send(to recipient: Recipient) throws {
    switch recipient.type {
        case .email:
            try Email.send()
        case .sms:
            try SMS.send()
        case .multiple(let enabledOptions):
            for option in enabledOptions {
//                try option.send()
            }
    }
}
struct Message: Encodable {
    let user: User
    let message: Body
    func send() throws {
        if user.isEmailOn {
            let email = Email(recipient: .init(type: .email(address: "")), message: message)
        }
        if user.isPhoneOn {
            let sms = SMS(recipient: .init(type: .sms(number: "")), message: message)
        }
    }
}
