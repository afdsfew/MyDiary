import SwiftUI

enum Category: String, CaseIterable, Codable {
    case study = "공부"
    case personal = "개인"
    case assignment = "과제"
    case other = "기타"
    
    func color(for colorScheme: ColorScheme) -> Color {
        AppTheme.categoryColor(self, for: colorScheme)
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
