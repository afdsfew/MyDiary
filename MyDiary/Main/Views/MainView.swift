import SwiftUI
import CoreData

struct MainView: View {

    @StateObject private var dateManager = DateManager()
    @StateObject private var todoViewModel: TodoViewModel
    @StateObject private var diaryViewModel: DiaryViewModel

    init(context: NSManagedObjectContext) {
        let dateManager = DateManager()
        _dateManager = StateObject(wrappedValue: dateManager)
        _todoViewModel = StateObject(wrappedValue: TodoViewModel(context: context, dateManager: dateManager))
        _diaryViewModel = StateObject(wrappedValue: DiaryViewModel(context: context, dateManager: dateManager))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 날짜 헤더 - DateManager의 selectedDate 직접 바인딩
                    DateHeaderView(selectedDate: $dateManager.selectedDate)

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
    }
}

// MARK: - Date Header View

struct DateHeaderView: View {

    @Binding var selectedDate: Date

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
            HapticManager.impact(.light)
        }
    }
}

#Preview {
    MainView(context: PersistenceController.preview.container.viewContext)
}
