import Vapor
import SMTPKitten

extension Request {
    func sendMessage(message: some MessageProtocol) async throws -> ClientResponse {
        try await message.send()
    }
}
//extension Application {
//    var messageProvider: MessageProvider {
//        switch MessageType {
//            case .email:
//                return .
//        }
//    }
//}
enum MessageType: Hashable {
    case email(String)
    case phone(String)
    indirect case multiple(Set<MessageType>)
}
protocol MessageTypes {
    
}
struct MessageBody: Content {}

protocol MessageProtocol: Codable {
    associatedtype Sender: Codable
    var sender: Sender { get }
    var recipient: any MessageReceivable { get }
    var body: MessageBody { get }
    var provider: MessageService { get }
    func send() async throws -> ClientResponse
}

extension MessageProtocol {
    func send() async throws -> ClientResponse {
//        switch recipient.address {
//            case .multiple(let types):
//                for type in types {
//                }
//                break
//            case .email(let address):
//                return try await Application.messageProvider(for: .email("")).send()
//            case .phone(let number):
//                break
//        }
        return .init()
    }
    
}
