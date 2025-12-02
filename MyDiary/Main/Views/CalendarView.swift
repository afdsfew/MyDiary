import SwiftUI

struct CalendarView: View {
    
    @Binding var selectedDate: Date
    let onDateSelected: (Date) -> Void
    
    @State private var currentMonth: Date = Date()
    
    private let calendar = Calendar.current
    private let daysOfWeek = ["일", "월", "화", "수", "목", "금", "토"]
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 16) {
            // 월 헤더
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                Text(monthYearString)
                    .font(.system(size: 18, weight: .bold))
                
                Spacer()
                
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            
            // 요일 헤더
            HStack(spacing: 0) {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // 날짜 그리드
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(daysInMonth, id: \.self) { date in
                    if let date = date {
                        DateCell(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            isToday: calendar.isDateInToday(date),
                            colorScheme: colorScheme
                        )
                        .onTapGesture {
                            selectedDate = date
                            onDateSelected(date)
                            
                            // 햅틱 피드백
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                        }
                    } else {
                        Color.clear
                            .frame(height: 40)
                    }
                }
            }
        }
        .padding(20)
        .background(AppTheme.cardBackground(for: colorScheme))
        .cornerRadius(20)
        .shadow(color: AppTheme.shadowColor(for: colorScheme), radius: 10, x: 0, y: 4)
        .padding(.horizontal, 16)
    }
    
    // MARK: - Computed Properties
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월"
        return formatter.string(from: currentMonth)
    }
    
    private var daysInMonth: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth) else {
            return []
        }
        
        let days = calendar.generateDates(
            inside: monthInterval,
            matching: DateComponents(hour: 0, minute: 0, second: 0)
        )
        
        // 첫 주의 빈 칸 계산
        let firstWeekday = calendar.component(.weekday, from: monthInterval.start)
        let leadingEmptyDays = Array(repeating: nil as Date?, count: firstWeekday - 1)
        
        return leadingEmptyDays + days.map { $0 as Date? }
    }
    
    // MARK: - Actions
    
    private func previousMonth() {
        if let newMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) {
            currentMonth = newMonth
        }
    }
    
    private func nextMonth() {
        if let newMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) {
            currentMonth = newMonth
        }
    }
}

// MARK: - Date Cell

struct DateCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let colorScheme: ColorScheme
    
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(calendar.component(.day, from: date))")
                .font(.system(size: 17, weight: isSelected ? .semibold : .regular))
                .foregroundColor(textColor)
                .frame(width: 44, height: 44)
                .background(backgroundColor)
                .cornerRadius(22)
            
            // 오늘 날짜 표시
            if isToday && !isSelected {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 5, height: 5)
            }
        }
    }
    
    private var textColor: Color {
        if isSelected {
            return .white
        }
        return AppTheme.textColor(for: colorScheme)
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return .blue
        }
        if isToday {
            return AppTheme.secondaryBackground(for: colorScheme)
        }
        return .clear
    }
}

// MARK: - Calendar Extension

extension Calendar {
    func generateDates(
        inside interval: DateInterval,
        matching components: DateComponents
    ) -> [Date] {
        var dates: [Date] = []
        dates.append(interval.start)
        
        enumerateDates(
            startingAfter: interval.start,
            matching: components,
            matchingPolicy: .nextTime
        ) { date, _, stop in
            if let date = date {
                if date < interval.end {
                    dates.append(date)
                } else {
                    stop = true
                }
            }
        }
        
        return dates
    }
}

#Preview {
    CalendarView(selectedDate: .constant(Date()), onDateSelected: { _ in })
}
