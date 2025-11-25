import Foundation

struct DateHelper {
    
    // MARK: - Date Key Generation
    
    /// 날짜를 "yyyy-MM-dd" 형식의 문자열로 변환
    static func dayKey(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    /// 문자열을 Date로 변환
    static func date(from dayKey: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dayKey)
    }
    
    // MARK: - Date Formatters
    
    /// 날짜를 "M월 d일 (E)" 형식으로 표시 (예: "11월 25일 (월)")
    static func displayFormat(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일 (E)"
        return formatter.string(from: date)
    }
    
    /// 시간을 "HH:mm" 형식으로 표시 (예: "15:30")
    static func timeFormat(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    // MARK: - Date Utilities
    
    /// 오늘 날짜의 시작 시간 (00:00:00)
    static func startOfDay(for date: Date = Date()) -> Date {
        return Calendar.current.startOfDay(for: date)
    }
    
    /// 두 날짜가 같은 날인지 확인
    static func isSameDay(_ date1: Date, _ date2: Date) -> Bool {
        return Calendar.current.isDate(date1, inSameDayAs: date2)
    }
    
    /// 오늘인지 확인
    static func isToday(_ date: Date) -> Bool {
        return Calendar.current.isDateInToday(date)
    }
}
