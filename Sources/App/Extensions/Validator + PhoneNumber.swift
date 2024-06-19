import Vapor

extension Validator where T == String {
    /// Validates whether a `String` is a valid phone number.
    public static var phoneNumber: Validator<T> {
        .init {
            guard let range = $0.range(of: User.phoneRegex, options: [.regularExpression]), range.lowerBound == $0.startIndex && range.upperBound == $0.endIndex
            else {
                return ValidatorResults.PhoneNumber(isValidPhoneNumber: false)
            }
            return ValidatorResults.PhoneNumber(isValidPhoneNumber: true)
        }
    }
}

extension ValidatorResults {
    /// `ValidatorResult` of a validator that validates whether a `String` is a valid email address.
    public struct PhoneNumber {
        /// The input is a valid email address
        public let isValidPhoneNumber: Bool
    }
}

extension ValidatorResults.PhoneNumber: ValidatorResult {
    public var isFailure: Bool {
        !self.isValidPhoneNumber
    }
    
    public var successDescription: String? {
        "is a valid phone number"
    }
    
    public var failureDescription: String? {
        "is not a valid phone number"
    }
}

