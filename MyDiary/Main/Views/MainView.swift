import SwiftUI
import CoreData

struct MainView: View {
    
    @StateObject private var todoViewModel: TodoViewModel
    @StateObject private var diaryViewModel: DiaryViewModel
    
    @State private var selectedDate: Date = Date()
    
    init(context: NSManagedObjectContext) {
        _todoViewModel = StateObject(wrappedValue: TodoViewModel(context: context))
        _diaryViewModel = StateObject(wrappedValue: DiaryViewModel(context: context))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 날짜 헤더
                    DateHeaderView(selectedDate: $selectedDate, 
                                 onDateChange: { date in
                        todoViewModel.selectDate(date)
                        diaryViewModel.selectDate(date)
                    })
                    
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
            .navigationTitle("My Diary")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            // 초기 날짜 동기화
            todoViewModel.selectDate(selectedDate)
            diaryViewModel.selectDate(selectedDate)
        }
    }
}

// MARK: - Date Header View

struct DateHeaderView: View {
    
    @Binding var selectedDate: Date
    let onDateChange: (Date) -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            // 날짜 표시
            Text(DateHelper.displayFormat(date: selectedDate))
                .font(.system(size: 24, weight: .bold, design: .default))
                .foregroundColor(.primary)
            
            // 날짜 선택 버튼
            HStack(spacing: 16) {
                // 이전 날짜
                Button(action: {
                    changeDate(by: -1)
                }) {
                    Image(systemName: "chevron.left.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.blue)
                }
                
                // 오늘로 이동
                Button(action: {
                    selectedDate = Date()
                    onDateChange(selectedDate)
                }) {
                    Text("오늘")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .cornerRadius(20)
                }
                
                // 다음 날짜
                Button(action: {
                    changeDate(by: 1)
                }) {
                    Image(systemName: "chevron.right.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(16)
        .padding(.horizontal)
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
