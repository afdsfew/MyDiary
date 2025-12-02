
import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // 샘플 Todo 데이터
        let categories: [Category] = [.study, .personal, .assignment, .other]
        let today = DateHelper.dayKey(from: Date())
        
        for i in 0..<5 {
            let newTodo = TodoItem(context: viewContext)
            newTodo.id = UUID()
            newTodo.title = "샘플 할 일 \(i + 1)"
            newTodo.isCompleted = i % 2 == 0
            newTodo.category = categories[i % categories.count].rawValue
            newTodo.dayKey = today
            newTodo.createdAt = Date()
        }
        
        // 샘플 Diary 데이터
        let newDiary = DiaryEntry(context: viewContext)
        newDiary.id = UUID()
        newDiary.content = "오늘은 프로젝트를 시작했습니다. SwiftUI와 CoreData를 활용한 할 일 관리 앱을 만들고 있어요!"
        newDiary.dayKey = today
        newDiary.timestamp = Date()
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "MyDiary")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // CoreData 에러 로깅
                print("⚠️ CoreData Error: \(error)")
                print("Error Info: \(error.userInfo)")
                
                // TODO: 프로덕션 환경에서는 사용자에게 알림
                // TODO: 인메모리 스토어로 폴백 옵션 제공
                
                // 디버그 빌드에서만 fatalError
                #if DEBUG
                fatalError("Unresolved error \(error), \(error.userInfo)")
                #else
                // 프로덕션에서는 에러 로깅만 하고 계속 진행
                print("❌ Failed to load persistent stores. App may not function correctly.")
                #endif
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
