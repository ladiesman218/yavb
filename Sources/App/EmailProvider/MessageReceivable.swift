import Vapor

//protocol RecipientName {
//    typealias Name = String
//}
//
//protocol RecipientAddress {
//    typealias Address = String
//}

//extension MessageReceivable {
//    var type: MessageType? {
//        get {
//            if address.range(of: User.emailRegex, options: .regularExpression) != nil {
//                return .email
//            } else if address.range(of: User.phoneRegex, options: .regularExpression) != nil {
//                return .sms
//            }
//            return nil
//        }
//    }
//}
//
//// Implementation of recipient
//struct Recipient: MessageReceivable {
//    var name: String? = nil
//    var address: String
//}

//protocol MessageReceivable: Codable {
//    var name: String? { get }
//    var address: MessageType { get }
//}
// Protocol for a valid recipient
protocol MessageReceivable {
    var name: String? { get }
    var address: String { get }
}
protocol MessageService {
    static var type: MessageType { get }
    func send() async throws -> ClientResponse
}
struct EmailServiceProvider: MessageService {
    static let type: MessageType = .email("")
    
    func send() async throws -> ClientResponse {
        return .init()
    }
}

struct SMSServiceProvider: MessageService {
    static let type: MessageType = .phone("")
    
    func send() async throws -> ClientResponse {
        return .init()
    }
}
extension Application {
    static func messageProvider(for type: MessageType) -> any MessageService {
        switch type {
            case .email:
                return EmailServiceProvider()
            case .phone:
                return SMSServiceProvider()
            default:
                fatalError()
        }
    }
//    static var messageProvider: any MessageService {
//        switch messageProvider.type {
//            case .email:
//                return EmailServiceProvider()
//            case .phone:
//                return SMSServiceProvider()
//            default:
//                break
//        }
//    }
}
