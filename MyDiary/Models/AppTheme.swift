import SwiftUI

// MARK: - Theme Mode
enum ThemeMode: String, CaseIterable {
    case light = "라이트"
    case dark = "다크"
    case system = "시스템"
    
    var icon: String {
        switch self {
        case .light:
            return "sun.max.fill"
        case .dark:
            return "moon.fill"
        case .system:
            return "circle.lefthalf.filled"
        }
    }
}

// MARK: - App Theme
struct AppTheme {
    
    // MARK: - Colors
    
    /// 메인 배경색
    static func backgroundColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(UIColor.systemBackground) : Color(UIColor.systemGroupedBackground)
    }
    
    /// 카드 배경색
    static func cardBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(UIColor.secondarySystemBackground) : Color.white
    }
    
    /// 보조 배경색
    static func secondaryBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(UIColor.tertiarySystemBackground) : Color(UIColor.systemGray6)
    }
    
    /// 텍스트 색상
    static func textColor(for colorScheme: ColorScheme) -> Color {
        Color.primary
    }
    
    /// 보조 텍스트 색상
    static func secondaryTextColor(for colorScheme: ColorScheme) -> Color {
        Color.secondary
    }
    
    /// 구분선 색상
    static func dividerColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(UIColor.separator) : Color(UIColor.systemGray4)
    }
    
    /// 그림자 색상
    static func shadowColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.black.opacity(0.3) : Color.black.opacity(0.08)
    }
    
    /// 액센트 색상
    static let accentColor = Color.blue
    
    // MARK: - Category Colors (Dark Mode Compatible)
    
    static func categoryColor(_ category: Category, for colorScheme: ColorScheme) -> Color {
        switch category {
        case .study:
            return colorScheme == .dark 
                ? Color(red: 0.4, green: 0.6, blue: 0.9)  // 더 진한 파스텔 블루
                : Color(red: 0.6, green: 0.8, blue: 1.0)  // 파스텔 블루
        case .personal:
            return colorScheme == .dark
                ? Color(red: 0.9, green: 0.5, blue: 0.7)  // 더 진한 파스텔 핑크
                : Color(red: 1.0, green: 0.8, blue: 0.9)  // 파스텔 핑크
        case .assignment:
            return colorScheme == .dark
                ? Color(red: 0.9, green: 0.7, blue: 0.3)  // 더 진한 파스텔 옐로우
                : Color(red: 1.0, green: 0.9, blue: 0.6)  // 파스텔 옐로우
        case .other:
            return colorScheme == .dark
                ? Color(red: 0.5, green: 0.7, blue: 0.5)  // 더 진한 파스텔 그린
                : Color(red: 0.8, green: 0.9, blue: 0.8)  // 파스텔 그린
        }
    }
}
