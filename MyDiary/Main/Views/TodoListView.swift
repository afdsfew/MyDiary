import SwiftUI

struct TodoListView: View {
    
    @ObservedObject var viewModel: TodoViewModel
    @State private var showingAddSheet = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 섹션 헤더
            HStack {
                Text("할 일")
                    .font(.system(size: 20, weight: .bold, design: .default))
                
                Spacer()
                
                // 완료 개수 표시
                Text("\(viewModel.completedCount)/\(viewModel.totalCount)")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                // 추가 버튼
                Button(action: {
                    showingAddSheet = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            
            // Todo 리스트
            if viewModel.todos.isEmpty {
                // 빈 상태
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 48))
                        .foregroundColor(.gray.opacity(0.3))
                    Text("할 일이 없습니다")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                List {
                    ForEach(viewModel.todos, id: \.id) { todo in
                        TodoRowView(todo: todo) {
                            viewModel.toggleCompletion(todo: todo)
                        }
                    }
                    .onDelete(perform: viewModel.deleteTodos)
                }
                .listStyle(PlainListStyle())
                .frame(maxHeight: 300)
                .scrollContentBackground(.hidden)
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddTodoSheet(viewModel: viewModel, isPresented: $showingAddSheet)
        }
        .alert("오류", isPresented: $viewModel.showError) {
            Button("확인", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "알 수 없는 오류가 발생했습니다.")
        }
    }
}
