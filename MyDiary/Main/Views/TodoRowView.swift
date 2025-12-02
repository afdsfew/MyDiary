import SwiftUI

struct TodoRowView: View {
    
    let todo: TodoItem
    let onToggle: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // 체크박스
            Button(action: {
                onToggle()
                HapticManager.impact(.light)
            }) {
                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(todo.isCompleted ? .green : .gray)
            }
            .buttonStyle(PlainButtonStyle())
            
            VStack(alignment: .leading, spacing: 4) {
                // 제목
                Text(todo.title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "제목 없음")
                    .font(.system(size: 16, weight: .medium, design: .default))
                    .strikethrough(todo.isCompleted, color: .gray)
                    .foregroundColor(todo.isCompleted ? .gray : .primary)
                
                // 카테고리 태그
                if let categoryString = todo.category,
                   let category = Category(rawValue: categoryString) {
                    HStack(spacing: 4) {
                        Image(systemName: category.icon)
                            .font(.system(size: 10))
                        Text(category.rawValue)
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(category.color)
                    .cornerRadius(8)
                }
            }
            
            Spacer()
            
            // 마감일 표시 (있는 경우)
            if let dueDate = todo.dueDate {
                Text(DateHelper.displayFormat(date: dueDate))
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}
