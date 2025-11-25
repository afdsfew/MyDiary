
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
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
