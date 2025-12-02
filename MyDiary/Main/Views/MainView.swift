import SwiftUI
import CoreData

struct MainView: View {
    
    @StateObject private var todoViewModel: TodoViewModel
    @StateObject private var diaryViewModel: DiaryViewModel
    
    @State private var selectedDate: Date = Date()
    @State private var showSettings = false
    @State private var showCalendar = false
    
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("themeMode") private var themeMode: String = ThemeMode.system.rawValue
    
    init(context: NSManagedObjectContext) {
        _todoViewModel = StateObject(wrappedValue: TodoViewModel(context: context))
        _diaryViewModel = StateObject(wrappedValue: DiaryViewModel(context: context))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 달력 뷰 (접기/펼치기)
                    if showCalendar {
                        CalendarView(selectedDate: $selectedDate) { date in
                            todoViewModel.selectDate(date)
                            diaryViewModel.selectDate(date)
                        }
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    // 날짜 헤더
                    DateHeaderView(
                        selectedDate: $selectedDate,
                        showCalendar: $showCalendar,
                        onDateChange: { date in
                            todoViewModel.selectDate(date)
                            diaryViewModel.selectDate(date)
                        }
                    )
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // Todo 리스트 섹션
                    TodoListView(viewModel: todoViewModel)
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // 메모 섹션
                    DiaryEditorView(viewModel: diaryViewModel)
                    
                    Spacer(minLength: 40)
                }
                .padding(.vertical)
            }
            .background(AppTheme.backgroundColor(for: colorScheme))
            .navigationTitle("My Diary")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .alert("오류", isPresented: .constant(todoViewModel.errorMessage != nil || diaryViewModel.errorMessage != nil)) {
                Button("확인") {
                    todoViewModel.errorMessage = nil
                    diaryViewModel.errorMessage = nil
                }
            } message: {
                Text(todoViewModel.errorMessage ?? diaryViewModel.errorMessage ?? "")
            }
        }
        .preferredColorScheme(colorSchemeForTheme)
        .onAppear {
            // 초기 날짜 동기화
            todoViewModel.selectDate(selectedDate)
            diaryViewModel.selectDate(selectedDate)
        }
    }
    
    
    private var colorSchemeForTheme: ColorScheme? {
        let mode = ThemeMode(rawValue: themeMode) ?? .system
        switch mode {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return nil
        }
    }
}

// MARK: - Date Header View

struct DateHeaderView: View {
    
    @Binding var selectedDate: Date
    @Binding var showCalendar: Bool
    let onDateChange: (Date) -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 12) {
            // 날짜 표시 및 달력 토글
            HStack {
                Text(DateHelper.displayFormat(date: selectedDate))
                    .font(.system(size: 28, weight: .bold, design: .default))
                    .foregroundColor(AppTheme.textColor(for: colorScheme))
                
                Spacer()
                
                Button(action: {
                    withAnimation(.spring()) {
                        showCalendar.toggle()
                    }
                    
                    // 햅틱 피드백
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                }) {
                    Image(systemName: showCalendar ? "calendar.badge.minus" : "calendar")
                        .font(.system(size: 22))
                        .foregroundColor(.blue)
                        .frame(width: 44, height: 44)
                        .background(AppTheme.secondaryBackground(for: colorScheme))
                        .cornerRadius(12)
                }
            }
            
            // 날짜 선택 버튼
            HStack(spacing: 12) {
                // 이전 날짜
                Button(action: {
                    changeDate(by: -1)
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.blue)
                        .frame(width: 44, height: 44)
                        .background(AppTheme.secondaryBackground(for: colorScheme))
                        .cornerRadius(12)
                }
                
                Spacer()
                
                // 오늘로 이동
                Button(action: {
                    selectedDate = Date()
                    onDateChange(selectedDate)
                }) {
                    Text("오늘")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                
                Spacer()
                
                // 다음 날짜
                Button(action: {
                    changeDate(by: 1)
                }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.blue)
                        .frame(width: 44, height: 44)
                        .background(AppTheme.secondaryBackground(for: colorScheme))
                        .cornerRadius(12)
                }
            }
        }
        .padding(20)
        .background(AppTheme.cardBackground(for: colorScheme))
        .cornerRadius(20)
        .shadow(color: AppTheme.shadowColor(for: colorScheme), radius: 10, x: 0, y: 4)
        .padding(.horizontal, 16)
    }
    
    private func changeDate(by days: Int) {
        if let newDate = Calendar.current.date(byAdding: .day, value: days, to: selectedDate) {
            selectedDate = newDate
            onDateChange(newDate)
            
            // 햅틱 피드백
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
    }
}

#Preview {
    MainView(context: PersistenceController.preview.container.viewContext)
}
