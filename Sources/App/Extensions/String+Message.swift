import Foundation
extension String {
    func countOccurrences(of substring: String) -> Int {
        var count = 0
        var searchStartIndex = startIndex
        
        while let range = self[searchStartIndex...].range(of: substring) {
            count += 1
            searchStartIndex = range.upperBound
        }
        
        return count
    }
    
    // If a string contains html tags, remove those tags
    var htmlRemoved: Self {
        // 定义匹配HTML标记的正则表达式
        let regex = try! NSRegularExpression(pattern: "<[^>]+>|\\{[^}]+\\}", options: .caseInsensitive)
        
        // 使用正则表达式替换匹配到的标记
        let range = NSRange(location: 0, length: self.utf16.count)
        let htmlAndCSSFree = regex.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: "")
        
        return htmlAndCSSFree
    }
}
