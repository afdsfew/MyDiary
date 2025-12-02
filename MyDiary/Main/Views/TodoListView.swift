import SwiftUI

struct TodoListView: View {
    
    @ObservedObject var viewModel: TodoViewModel
    @State private var showingAddSheet = false
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 헤더
            HStack {
                Text("할 일")
                    .font(.system(size: 22, weight: .bold, design: .default))
                
                Spacer()
                
                // 완료 개수
                Text("\(viewModel.completedCount)/\(viewModel.totalCount)")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                
                // 추가 버튼
                Button(action: {
                    showingAddSheet = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            // Todo 리스트
            if viewModel.todos.isEmpty {
                // 빈 상태
                VStack(spacing: 12) {
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
                VStack(spacing: 8) {
                    ForEach(viewModel.todos, id: \.id) { todo in
                        TodoRowView(
                            todo: todo,
                            onToggle: {
                                viewModel.toggleCompletion(todo: todo)
                            }
                        )
                    }
                    .onDelete { indexSet in
                        viewModel.deleteTodos(at: indexSet)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .background(AppTheme.cardBackground(for: colorScheme))
        .cornerRadius(20)
        .shadow(color: AppTheme.shadowColor(for: colorScheme), radius: 10, x: 0, y: 4)
        .padding(.horizontal, 16)
        .sheet(isPresented: $showingAddSheet) {
            AddTodoSheet(viewModel: viewModel, isPresented: $showingAddSheet)
        }
    }
}
