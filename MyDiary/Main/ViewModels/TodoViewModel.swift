import Foundation
import CoreData
import Combine

class TodoViewModel: ObservableObject {
    
    @Published var todos: [TodoItem] = []
    @Published var selectedDate: Date = Date()
    @Published var errorMessage: String?
    
    private let viewContext: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.viewContext = context
        fetchTodos()
    }
    
    // MARK: - Fetch Todos
    
    /// 선택된 날짜의 Todo 항목들을 가져옴
    func fetchTodos() {
        let dayKey = DateHelper.dayKey(from: selectedDate)
        let request: NSFetchRequest<TodoItem> = TodoItem.fetchRequest()
        request.predicate = NSPredicate(format: "dayKey == %@", dayKey)
        request.sortDescriptors = [
            NSSortDescriptor(key: "isCompleted", ascending: true),
            NSSortDescriptor(key: "createdAt", ascending: true)
        ]
        
        do {
            todos = try viewContext.fetch(request)
            errorMessage = nil
        } catch {
            print("Failed to fetch todos: \(error)")
            errorMessage = "할 일을 불러오는데 실패했습니다."
            todos = []
        }
    }
    
    // MARK: - Create Todo
    
    /// 새로운 Todo 추가
    func addTodo(title: String, category: Category, dueDate: Date? = nil) {
        let newTodo = TodoItem(context: viewContext)
        newTodo.id = UUID()
        newTodo.title = title
        newTodo.isCompleted = false
        newTodo.category = category.rawValue
        newTodo.dueDate = dueDate
        newTodo.dayKey = DateHelper.dayKey(from: selectedDate)
        newTodo.createdAt = Date()
        
        saveContext()
        fetchTodos()
    }
    
    // MARK: - Update Todo
    
    /// Todo 완료 상태 토글
    func toggleCompletion(todo: TodoItem) {
        todo.isCompleted.toggle()
        saveContext()
        fetchTodos()
    }
    
    /// Todo 수정
    func updateTodo(todo: TodoItem, title: String, category: Category, dueDate: Date?) {
        todo.title = title
        todo.category = category.rawValue
        todo.dueDate = dueDate
        
        saveContext()
        fetchTodos()
    }
    
    // MARK: - Delete Todo
    
    /// Todo 삭제
    func deleteTodo(todo: TodoItem) {
        viewContext.delete(todo)
        saveContext()
        fetchTodos()
    }
    
    /// IndexSet으로 Todo 삭제
    func deleteTodos(at offsets: IndexSet) {
        offsets.map { todos[$0] }.forEach(viewContext.delete)
        saveContext()
        fetchTodos()
    }
    
    // MARK: - Date Selection
    
    /// 날짜 변경
    func selectDate(_ date: Date) {
        selectedDate = date
        fetchTodos()
    }
    
    // MARK: - Statistics
    
    /// 완료된 Todo 개수
    var completedCount: Int {
        todos.filter { $0.isCompleted }.count
    }
    
    /// 전체 Todo 개수
    var totalCount: Int {
        todos.count
    }
    
    // MARK: - Private Methods
    
    private func saveContext() {
        do {
            try viewContext.save()
            errorMessage = nil
        } catch {
            print("Failed to save context: \(error)")
            errorMessage = "저장하는데 실패했습니다."
        }
    }
}
