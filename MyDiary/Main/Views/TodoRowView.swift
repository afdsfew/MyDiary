import SwiftUI

struct TodoRowView: View {
    
    let todo: TodoItem
    let onToggle: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 14) {
            // 체크박스
            Button(action: {
                onToggle()
                // 햅틱 피드백
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
            }) {
                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 28))
                    .foregroundColor(todo.isCompleted ? .green : .gray)
            }
            .buttonStyle(PlainButtonStyle())
            
            VStack(alignment: .leading, spacing: 6) {
                // 제목
                Text(todo.title ?? "")
                    .font(.system(size: 17, weight: .medium, design: .default))
                    .strikethrough(todo.isCompleted, color: .gray)
                    .foregroundColor(todo.isCompleted ? .gray : .primary)
                
                // 카테고리 태그
                if let categoryString = todo.category,
                   let category = Category(rawValue: categoryString) {
                    HStack(spacing: 6) {
                        Image(systemName: category.icon)
                            .font(.system(size: 11))
                        Text(category.rawValue)
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(category.color(for: colorScheme))
                    .cornerRadius(10)
                }
            }
            
            Spacer()
            
            // 마감일 표시 (있는 경우)
            if let dueDate = todo.dueDate {
                Text(DateHelper.displayFormat(date: dueDate))
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 12)
    }
}
