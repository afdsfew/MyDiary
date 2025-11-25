import SwiftUI

enum Category: String, CaseIterable, Codable {
    case study = "공부"
    case personal = "개인"
    case assignment = "과제"
    case other = "기타"
    
    var color: Color {
        switch self {
        case .study:
            return Color(red: 0.6, green: 0.8, blue: 1.0) // 파스텔 블루
        case .personal:
            return Color(red: 1.0, green: 0.8, blue: 0.9) // 파스텔 핑크
        case .assignment:
            return Color(red: 1.0, green: 0.9, blue: 0.6) // 파스텔 옐로우
        case .other:
            return Color(red: 0.8, green: 0.9, blue: 0.8) // 파스텔 그린
        }
    }
    
    var icon: String {
        switch self {
        case .study:
            return "book.fill"
        case .personal:
            return "person.fill"
        case .assignment:
            return "doc.text.fill"
        case .other:
            return "star.fill"
        }
    }
}
