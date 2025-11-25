import SwiftUI

struct AddTodoSheet: View {
    
    @ObservedObject var viewModel: TodoViewModel
    @Binding var isPresented: Bool
    
    @State private var title: String = ""
    @State private var selectedCategory: Category = .other
    @State private var hasDueDate: Bool = false
    @State private var dueDate: Date = Date()
    
    var body: some View {
        NavigationView {
            Form {
                // 제목 입력
                Section(header: Text("제목")) {
                    TextField("할 일을 입력하세요", text: $title)
                        .font(.system(size: 16))
                }
                
                // 카테고리 선택
                Section(header: Text("카테고리")) {
                    Picker("카테고리", selection: $selectedCategory) {
                        ForEach(Category.allCases, id: \.self) { category in
                            HStack {
                                Image(systemName: category.icon)
                                Text(category.rawValue)
                            }
                            .tag(category)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                // 마감일 선택
                Section(header: Text("마감일")) {
                    Toggle("마감일 설정", isOn: $hasDueDate)
                    
                    if hasDueDate {
                        DatePicker("날짜", selection: $dueDate, displayedComponents: .date)
                            .datePickerStyle(GraphicalDatePickerStyle())
                    }
                }
            }
            .navigationTitle("새로운 할 일")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("저장") {
                        saveTodo()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private func saveTodo() {
        let finalDueDate = hasDueDate ? dueDate : nil
        viewModel.addTodo(title: title, category: selectedCategory, dueDate: finalDueDate)
        
        // 햅틱 피드백
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        isPresented = false
    }
}
