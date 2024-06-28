import Vapor

protocol BrevoMessage: Content {
    associatedtype Sender: Codable
    associatedtype Recipient: Codable
    static var sender: Sender { get }

    var subject: String? { get }
    var recipient: Recipient { get }
    var content: String { get }
    
    // Must have customized codingkeys to map property names to required field names
    // Be sure to encode `Self.sender` as `sender` in both sms and email implementation
    associatedtype CodingKeys: CodingKey
//    var customCodingKeys: [CodingKey] { get }
}

extension BrevoMessage {
    init(from decoder: any Decoder) throws {
        fatalError()
    }
}
