# MyDiary 코드 검토 보고서

> 작성일: 2025-12-02
> 검토자: Claude Code
> 프로젝트: MyDiary - SwiftUI + CoreData 할 일 관리 앱

## 목차

1. [심각한 문제 (즉시 수정 필요)](#-심각한-문제-즉시-수정-필요)
2. [중요한 문제 (곧 수정 권장)](#-중요한-문제-곧-수정-권장)
3. [개선 사항 (향후 고려)](#-개선-사항-향후-고려)
4. [코드 품질 요약](#-코드-품질-요약)
5. [우선순위 개선 로드맵](#-우선순위-개선-로드맵)

---

## 🔴 심각한 문제 (즉시 수정 필요)

### 1. 메모리 누수 위험: 자동 저장 디바운싱

**파일:** `DiaryEditorView.swift:41-46`

**현재 코드:**
```swift
.onChange(of: viewModel.diaryContent) { oldValue, newValue in
    // 자동 저장 (디바운싱)
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
        viewModel.saveDiary()
    }
}
```

**문제점:**
- ❌ 매 글자 입력마다 새로운 1초 타이머가 생성됨
- ❌ 이전 타이머가 취소되지 않아 중복 저장 발생 가능
- ❌ 100글자를 빠르게 입력하면 100개의 타이머가 생성됨
- ❌ 메모리 낭비 및 불필요한 CoreData 저장 연산

**영향도:** 높음 - 사용자가 긴 글을 작성하면 앱 성능 저하 및 배터리 소모

**개선 방안:**

```swift
// DiaryViewModel.swift에 추가
class DiaryViewModel: ObservableObject {
    // ... 기존 코드 ...

    private var saveTask: Task<Void, Never>?

    // 기존 saveDiary()는 그대로 유지

    // 새 메서드 추가
    func scheduleSave() {
        saveTask?.cancel()  // 이전 타이머 취소 ✅
        saveTask = Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            if !Task.isCancelled {
                await MainActor.run {
                    saveDiary()
                }
            }
        }
    }
}

// DiaryEditorView.swift 수정
.onChange(of: viewModel.diaryContent) { oldValue, newValue in
    viewModel.scheduleSave()  // 개선된 메서드 사용 ✅
}
```

**예상 효과:**
- ✅ 이전 타이머 자동 취소
- ✅ 항상 하나의 타이머만 존재
- ✅ 메모리 사용량 감소
- ✅ 불필요한 저장 연산 방지

---

### 2. 에러 처리 부족: 사용자에게 에러 알림 없음

**파일:**
- `TodoViewModel.swift:32`
- `DiaryViewModel.swift:40`
- `Persistence.swift:62`

**현재 코드:**
```swift
// TodoViewModel.swift
func fetchTodos() {
    // ...
    do {
        todos = try viewContext.fetch(request)
    } catch {
        print("Failed to fetch todos: \(error)")  // ❌ 콘솔에만 출력
    }
}

// Persistence.swift
container.loadPersistentStores(completionHandler: { (storeDescription, error) in
    if let error = error as NSError? {
        fatalError("Unresolved error \(error), \(error.userInfo)")  // ❌ 앱 강제 종료
    }
})
```

**문제점:**
- ❌ 데이터 로드/저장 실패 시 사용자가 알 수 없음
- ❌ 앱이 조용히 실패하여 디버깅이 어려움
- ❌ `fatalError()`는 앱을 강제 종료시킴 (프로덕션 부적합)
- ❌ 사용자 경험 저하

**영향도:** 높음 - 데이터 손실 및 앱 크래시 가능

**개선 방안:**

```swift
// TodoViewModel.swift
class TodoViewModel: ObservableObject {
    @Published var todos: [TodoItem] = []
    @Published var selectedDate: Date = Date()
    @Published var errorMessage: String?  // ✅ 추가
    @Published var showError: Bool = false  // ✅ 추가

    // ... 기존 코드 ...

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
            errorMessage = nil  // ✅ 성공 시 에러 메시지 초기화
        } catch {
            print("Failed to fetch todos: \(error)")
            errorMessage = "할 일을 불러오는데 실패했습니다."  // ✅ 사용자용 메시지
            showError = true  // ✅ 에러 알림 표시
            todos = []  // ✅ 안전한 기본값
        }
    }

    private func saveContext() {
        do {
            try viewContext.save()
            errorMessage = nil
        } catch {
            print("Failed to save context: \(error)")
            errorMessage = "저장에 실패했습니다. 다시 시도해주세요."  // ✅
            showError = true  // ✅
        }
    }
}

// TodoListView.swift에 추가
struct TodoListView: View {
    @ObservedObject var viewModel: TodoViewModel
    @State private var showingAddSheet = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // ... 기존 코드 ...
        }
        .sheet(isPresented: $showingAddSheet) {
            AddTodoSheet(viewModel: viewModel, isPresented: $showingAddSheet)
        }
        .alert("오류", isPresented: $viewModel.showError) {  // ✅ 에러 알림 추가
            Button("확인", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "알 수 없는 오류가 발생했습니다.")
        }
    }
}
```

**Persistence.swift 개선:**
```swift
init(inMemory: Bool = false) {
    container = NSPersistentContainer(name: "MyDiary")
    if inMemory {
        container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
    }
    container.loadPersistentStores(completionHandler: { (storeDescription, error) in
        if let error = error as NSError? {
            // ✅ 프로덕션 환경에서는 fatalError 대신 적절한 처리
            #if DEBUG
            fatalError("Unresolved error \(error), \(error.userInfo)")
            #else
            // 에러 로깅 서비스로 전송 (Firebase Crashlytics 등)
            print("CoreData initialization failed: \(error)")
            // 인메모리 스토어로 폴백
            #endif
        }
    })
    container.viewContext.automaticallyMergesChangesFromParent = true
}
```

---

### 3. Optional 강제 언래핑 위험

**파일:** `TodoRowView.swift:25`, `31-32`

**현재 코드:**
```swift
// TodoRowView.swift
Text(todo.title ?? "")  // ⚠️ 빈 문자열로 fallback

if let categoryString = todo.category,
   let category = Category(rawValue: categoryString) {
    // 카테고리 표시
}
```

**문제점:**
- ⚠️ CoreData에서 `title`이 필수 속성으로 정의되어 있지만 nil일 수 있음
- ⚠️ 빈 제목의 todo가 생성될 수 있음
- ⚠️ UI에서 빈 행이 표시되어 사용자 혼란 야기

**영향도:** 중간 - UI/UX 저하

**개선 방안:**

```swift
// TodoRowView.swift
Text(todo.title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "제목 없음")
    .font(.system(size: 16, weight: .medium, design: .default))
    .strikethrough(todo.isCompleted, color: .gray)
    .foregroundColor(todo.isCompleted ? .gray : .primary)
```

**AddTodoSheet의 검증은 이미 잘 구현되어 있음 ✅:**
```swift
// AddTodoSheet.swift:59
.disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
```

---

## 🟡 중요한 문제 (곧 수정 권장)

### 4. 날짜 동기화 문제

**파일:** `MainView.swift:9-49`

**현재 구조:**
```swift
// MainView에 selectedDate 존재
@State private var selectedDate: Date = Date()

// TodoViewModel에도 selectedDate 존재
@Published var selectedDate: Date = Date()

// DiaryViewModel에도 selectedDate 존재
@Published var selectedDate: Date = Date()
```

**문제점:**
- ❌ 세 곳에 같은 상태가 중복 저장됨
- ❌ 수동 동기화 필요 (에러 가능성)
- ❌ Single Source of Truth 원칙 위배
- ❌ 동기화 실패 시 데이터 불일치 발생

**영향도:** 중간 - 버그 발생 가능성

**현재 동기화 방식:**
```swift
DateHeaderView(selectedDate: $selectedDate,
             onDateChange: { date in
    todoViewModel.selectDate(date)  // 수동 호출
    diaryViewModel.selectDate(date)  // 수동 호출
})
```

**개선 방안:**

**방법 1: DateManager를 이용한 중앙 집중식 관리**

```swift
// DateManager.swift (새 파일)
import Foundation
import Combine

class DateManager: ObservableObject {
    @Published var selectedDate: Date = Date()
}

// TodoViewModel.swift
class TodoViewModel: ObservableObject {
    @Published var todos: [TodoItem] = []

    private let viewContext: NSManagedObjectContext
    private let dateManager: DateManager
    private var cancellables = Set<AnyCancellable>()

    init(context: NSManagedObjectContext, dateManager: DateManager) {
        self.viewContext = context
        self.dateManager = dateManager

        // dateManager의 날짜 변경 감지 ✅
        dateManager.$selectedDate
            .sink { [weak self] _ in
                self?.fetchTodos()
            }
            .store(in: &cancellables)

        fetchTodos()
    }

    func fetchTodos() {
        let dayKey = DateHelper.dayKey(from: dateManager.selectedDate)  // ✅
        // ... 나머지 코드
    }

    // selectDate 메서드 제거 또는 dateManager로 위임
}

// DiaryViewModel.swift도 동일하게 수정

// MainView.swift
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
                    // 날짜 헤더 - Binding으로 직접 연결 ✅
                    DateHeaderView(selectedDate: $dateManager.selectedDate)

                    Divider().padding(.horizontal)

                    TodoListView(viewModel: todoViewModel)

                    Divider().padding(.horizontal)

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

// DateHeaderView.swift - onDateChange 클로저 제거 ✅
struct DateHeaderView: View {
    @Binding var selectedDate: Date
    // let onDateChange: (Date) -> Void  // 제거

    var body: some View {
        VStack(spacing: 8) {
            Text(DateHelper.displayFormat(date: selectedDate))
                .font(.system(size: 24, weight: .bold, design: .default))
                .foregroundColor(.primary)

            HStack(spacing: 16) {
                Button(action: { changeDate(by: -1) }) {
                    Image(systemName: "chevron.left.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.blue)
                }

                Button(action: {
                    selectedDate = Date()  // ✅ Binding으로 직접 업데이트
                }) {
                    Text("오늘")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .cornerRadius(20)
                }

                Button(action: { changeDate(by: 1) }) {
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
            selectedDate = newDate  // ✅ Binding으로 직접 업데이트

            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
    }
}
```

**예상 효과:**
- ✅ Single Source of Truth
- ✅ 자동 동기화 (Combine 활용)
- ✅ 수동 동기화 코드 제거
- ✅ 버그 발생 가능성 감소

---

### 5. List 높이 계산 방식 문제

**파일:** `TodoListView.swift:56`

**현재 코드:**
```swift
.frame(height: CGFloat(min(viewModel.todos.count, 5)) * 60)
```

**문제점:**
- ❌ 하드코딩된 행 높이 (60)
- ❌ 실제 행 높이와 다를 수 있음
- ❌ Dynamic Type 크기 변경 시 레이아웃 깨질 수 있음
- ❌ 5개 이상의 todo가 있으면 정확한 높이가 아님

**영향도:** 중간 - UI/UX 일관성 저하

**개선 방안:**

```swift
// TodoListView.swift
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

                Text("\(viewModel.completedCount)/\(viewModel.totalCount)")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)

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
                .frame(maxHeight: 300)  // ✅ 최대 높이만 제한 (자연스러운 높이 사용)
                .scrollContentBackground(.hidden)  // iOS 16+
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddTodoSheet(viewModel: viewModel, isPresented: $showingAddSheet)
        }
    }
}
```

**또는 ScrollView 사용:**
```swift
ScrollView {
    LazyVStack(spacing: 8) {
        ForEach(viewModel.todos, id: \.id) { todo in
            TodoRowView(todo: todo) {
                viewModel.toggleCompletion(todo: todo)
            }
            .swipeActions(edge: .trailing) {
                Button(role: .destructive) {
                    viewModel.deleteTodo(todo: todo)
                } label: {
                    Label("삭제", systemImage: "trash")
                }
            }
        }
    }
    .padding(.horizontal)
}
.frame(maxHeight: 300)
```

---

### 6. CoreData 저장 후 불필요한 재조회

**파일:**
- `TodoViewModel.swift:49-50, 58-59, 68-69, 77-78, 84-85`
- `DiaryViewModel.swift:81, 85`

**현재 코드:**
```swift
func addTodo(title: String, category: Category, dueDate: Date? = nil) {
    let newTodo = TodoItem(context: viewContext)
    // ... 속성 설정
    saveContext()
    fetchTodos()  // ❌ 불필요한 재조회
}

func toggleCompletion(todo: TodoItem) {
    todo.isCompleted.toggle()
    saveContext()
    fetchTodos()  // ❌ 불필요한 재조회
}

func deleteTodo(todo: TodoItem) {
    viewContext.delete(todo)
    saveContext()
    fetchTodos()  // ❌ 불필요한 재조회
}
```

**문제점:**
- ❌ 모든 CRUD 작업 후 전체 데이터를 다시 조회
- ❌ `@Published var todos`가 CoreData 객체를 직접 참조
- ❌ 불필요한 데이터베이스 쿼리로 성능 저하
- ❌ 특히 많은 항목이 있을 때 체감 지연 발생

**영향도:** 중간 - 성능 저하

**분석:**
CoreData의 `NSManagedObject`는 변경 사항을 자동으로 추적하지만, SwiftUI의 `@Published` 배열은 배열 자체가 교체되어야 UI 업데이트가 발생합니다. 따라서 다음 두 가지 접근 방법이 있습니다:

**방법 1: NSFetchedResultsController 사용 (권장)**

```swift
import Foundation
import CoreData
import Combine

class TodoViewModel: NSObject, ObservableObject {
    @Published var todos: [TodoItem] = []
    @Published var selectedDate: Date = Date() {
        didSet {
            updateFetchRequest()
        }
    }

    private let viewContext: NSManagedObjectContext
    private var fetchedResultsController: NSFetchedResultsController<TodoItem>!

    init(context: NSManagedObjectContext) {
        self.viewContext = context
        super.init()
        setupFetchedResultsController()
    }

    private func setupFetchedResultsController() {
        let request: NSFetchRequest<TodoItem> = TodoItem.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(key: "isCompleted", ascending: true),
            NSSortDescriptor(key: "createdAt", ascending: true)
        ]
        request.predicate = NSPredicate(format: "dayKey == %@", DateHelper.dayKey(from: selectedDate))

        fetchedResultsController = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: viewContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )

        fetchedResultsController.delegate = self

        do {
            try fetchedResultsController.performFetch()
            todos = fetchedResultsController.fetchedObjects ?? []
        } catch {
            print("Failed to fetch todos: \(error)")
            todos = []
        }
    }

    private func updateFetchRequest() {
        fetchedResultsController.fetchRequest.predicate = NSPredicate(
            format: "dayKey == %@",
            DateHelper.dayKey(from: selectedDate)
        )

        do {
            try fetchedResultsController.performFetch()
            todos = fetchedResultsController.fetchedObjects ?? []
        } catch {
            print("Failed to update fetch: \(error)")
        }
    }

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
        // fetchTodos() 제거 ✅ - NSFetchedResultsController가 자동 업데이트
    }

    func toggleCompletion(todo: TodoItem) {
        todo.isCompleted.toggle()
        saveContext()
        // fetchTodos() 제거 ✅
    }

    // ... 나머지 메서드도 동일하게 fetchTodos() 제거

    // MARK: - Statistics

    var completedCount: Int {
        todos.filter { $0.isCompleted }.count
    }

    var totalCount: Int {
        todos.count
    }

    // MARK: - Private Methods

    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            print("Failed to save context: \(error)")
        }
    }
}

// MARK: - NSFetchedResultsControllerDelegate

extension TodoViewModel: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        todos = fetchedResultsController.fetchedObjects ?? []  // ✅ 자동 업데이트
    }
}
```

**방법 2: 수동 배열 조작 (간단한 경우)**

```swift
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

    // 배열에 직접 추가 후 정렬 ✅
    todos.append(newTodo)
    sortTodos()
}

func deleteTodo(todo: TodoItem) {
    viewContext.delete(todo)
    saveContext()

    // 배열에서 직접 제거 ✅
    todos.removeAll { $0.id == todo.id }
}

private func sortTodos() {
    todos.sort { lhs, rhs in
        if lhs.isCompleted != rhs.isCompleted {
            return !lhs.isCompleted  // 미완료 항목 먼저
        }
        return (lhs.createdAt ?? Date()) < (rhs.createdAt ?? Date())
    }
}
```

**예상 효과:**
- ✅ 불필요한 fetch 쿼리 제거
- ✅ 성능 향상 (특히 많은 항목 있을 때)
- ✅ 자동 업데이트로 코드 간소화

---

### 7. DateFormatter 객체 중복 생성

**파일:** `DateHelper.swift:8-36`

**현재 코드:**
```swift
static func dayKey(from date: Date) -> String {
    let formatter = DateFormatter()  // ❌ 매번 새로 생성
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.string(from: date)
}

static func displayFormat(date: Date) -> String {
    let formatter = DateFormatter()  // ❌ 매번 새로 생성
    formatter.locale = Locale(identifier: "ko_KR")
    formatter.dateFormat = "M월 d일 (E)"
    return formatter.string(from: date)
}
```

**문제점:**
- ❌ `DateFormatter` 생성은 매우 비용이 큰 연산 (Apple 공식 문서 명시)
- ❌ 앱에서 매우 자주 호출되는 함수 (날짜 표시, dayKey 생성 등)
- ❌ 매 호출마다 새 객체 생성으로 성능 낭비

**영향도:** 중간 - 반복적인 성능 저하

**개선 방안:**

```swift
// DateHelper.swift
import Foundation

struct DateHelper {

    // MARK: - Private Formatters (재사용) ✅

    private static let dayKeyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")  // ✅ 일관성 보장
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()

    private static let displayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일 (E)"
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    // MARK: - Date Key Generation

    /// 날짜를 "yyyy-MM-dd" 형식의 문자열로 변환
    static func dayKey(from date: Date) -> String {
        return dayKeyFormatter.string(from: date)  // ✅ 재사용
    }

    /// 문자열을 Date로 변환
    static func date(from dayKey: String) -> Date? {
        return dayKeyFormatter.date(from: dayKey)  // ✅ 재사용
    }

    // MARK: - Date Formatters

    /// 날짜를 "M월 d일 (E)" 형식으로 표시 (예: "11월 25일 (월)")
    static func displayFormat(date: Date) -> String {
        return displayFormatter.string(from: date)  // ✅ 재사용
    }

    /// 시간을 "HH:mm" 형식으로 표시 (예: "15:30")
    static func timeFormat(date: Date) -> String {
        return timeFormatter.string(from: date)  // ✅ 재사용
    }

    // MARK: - Date Utilities

    /// 오늘 날짜의 시작 시간 (00:00:00)
    static func startOfDay(for date: Date = Date()) -> Date {
        return Calendar.current.startOfDay(for: date)
    }

    /// 두 날짜가 같은 날인지 확인
    static func isSameDay(_ date1: Date, _ date2: Date) -> Bool {
        return Calendar.current.isDate(date1, inSameDayAs: date2)
    }

    /// 오늘인지 확인
    static func isToday(_ date: Date) -> Bool {
        return Calendar.current.isDateInToday(date)
    }
}
```

**예상 효과:**
- ✅ DateFormatter 생성 비용 제거 (약 10-100배 성능 향상)
- ✅ 메모리 사용량 감소
- ✅ 앱 전체 성능 개선
- ✅ 배터리 소모 감소

---

## 🟢 개선 사항 (향후 고려)

### 8. 빈 파일 정리

**파일:**
- `CalendarView.swift` (완전히 빈 파일)
- `AppScreen.swift` (완전히 빈 파일)

**문제점:**
- 프로젝트에 사용되지 않는 빈 파일 존재
- 코드베이스 혼란

**권장 조치:**
1. 사용할 예정이면 구현
2. 사용하지 않으면 Xcode에서 제거

---

### 9. Deprecated 파일 제거

**파일:** `ContentView.swift`

**현재 상태:**
```swift
// DEPRECATED: This file is no longer used. MainView is now the main entry point.
// Keeping this file for reference only. All code is commented out to prevent build errors.
```

**권장 조치:**
- 프로젝트에서 완전히 제거
- Git 히스토리에 남아있으므로 필요시 복구 가능
- 깔끔한 코드베이스 유지

---

### 10. Preview 데이터 개선

**파일:** `Persistence.swift:8-40`

**현재 문제:**
- 샘플 데이터가 오늘 날짜만 있음
- 다양한 시나리오 테스트 어려움

**개선 방안:**

```swift
@MainActor
static let preview: PersistenceController = {
    let result = PersistenceController(inMemory: true)
    let viewContext = result.container.viewContext

    let categories: [Category] = [.study, .personal, .assignment, .other]
    let calendar = Calendar.current
    let today = Date()
    let todayKey = DateHelper.dayKey(from: today)

    // 오늘 할 일 (다양한 상태)
    let todoTitles = [
        ("SwiftUI 공부하기", Category.study, false, true),  // (제목, 카테고리, 완료여부, 마감일있음)
        ("장보기", Category.personal, true, false),
        ("프로젝트 제출", Category.assignment, false, true),
        ("운동하기", Category.other, false, false),
    ]

    for (index, todoData) in todoTitles.enumerated() {
        let newTodo = TodoItem(context: viewContext)
        newTodo.id = UUID()
        newTodo.title = todoData.0
        newTodo.isCompleted = todoData.2
        newTodo.category = todoData.1.rawValue
        newTodo.dayKey = todayKey
        newTodo.createdAt = calendar.date(byAdding: .minute, value: -index * 10, to: today)!

        if todoData.3 {
            newTodo.dueDate = calendar.date(byAdding: .day, value: 1, to: today)!
        }
    }

    // 어제 할 일 (완료된 항목)
    if let yesterday = calendar.date(byAdding: .day, value: -1, to: today) {
        let yesterdayKey = DateHelper.dayKey(from: yesterday)

        let yesterdayTodo = TodoItem(context: viewContext)
        yesterdayTodo.id = UUID()
        yesterdayTodo.title = "어제 완료한 일"
        yesterdayTodo.isCompleted = true
        yesterdayTodo.category = Category.study.rawValue
        yesterdayTodo.dayKey = yesterdayKey
        yesterdayTodo.createdAt = yesterday

        // 어제 일기
        let yesterdayDiary = DiaryEntry(context: viewContext)
        yesterdayDiary.id = UUID()
        yesterdayDiary.content = "어제는 기획을 마무리했습니다. 프로젝트가 잘 진행되고 있어요!"
        yesterdayDiary.dayKey = yesterdayKey
        yesterdayDiary.timestamp = yesterday
    }

    // 오늘 일기
    let todayDiary = DiaryEntry(context: viewContext)
    todayDiary.id = UUID()
    todayDiary.content = """
    오늘은 프로젝트를 본격적으로 시작했습니다.

    SwiftUI와 CoreData를 활용한 할 일 관리 앱을 만들고 있는데, 생각보다 재미있네요!

    내일은 테스트 코드를 작성해볼 계획입니다.
    """
    todayDiary.dayKey = todayKey
    todayDiary.timestamp = today

    do {
        try viewContext.save()
    } catch {
        let nsError = error as NSError
        fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
    }
    return result
}()
```

---

### 11. 접근성 (Accessibility) 개선

**현재 문제:**
- VoiceOver 사용자를 위한 레이블 부족
- 스크린 리더 지원 미흡

**개선 방안:**

```swift
// TodoRowView.swift
Button(action: {
    onToggle()
    let generator = UIImpactFeedbackGenerator(style: .light)
    generator.impactOccurred()
}) {
    Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
        .font(.system(size: 24))
        .foregroundColor(todo.isCompleted ? .green : .gray)
}
.buttonStyle(PlainButtonStyle())
.accessibilityLabel(todo.isCompleted ? "완료됨" : "미완료")  // ✅
.accessibilityHint("탭하여 완료 상태를 변경합니다")  // ✅
.accessibilityAddTraits(.isButton)  // ✅

// DateHeaderView.swift
Button(action: { changeDate(by: -1) }) {
    Image(systemName: "chevron.left.circle.fill")
        .font(.system(size: 28))
        .foregroundColor(.blue)
}
.accessibilityLabel("이전 날짜")  // ✅
.accessibilityHint("이전 날짜로 이동합니다")  // ✅

Button(action: { changeDate(by: 1) }) {
    Image(systemName: "chevron.right.circle.fill")
        .font(.system(size: 28))
        .foregroundColor(.blue)
}
.accessibilityLabel("다음 날짜")  // ✅
.accessibilityHint("다음 날짜로 이동합니다")  // ✅

// DiaryEditorView.swift
TextEditor(text: $viewModel.diaryContent)
    .font(.system(size: 16))
    .padding(.horizontal, 12)
    .padding(.vertical, 12)
    .accessibilityLabel("오늘의 메모")  // ✅
    .accessibilityHint("오늘 하루를 기록할 수 있습니다")  // ✅
```

---

### 12. Identifiable 프로토콜 명시적 구현

**현재 코드:**
```swift
ForEach(viewModel.todos, id: \.id) { todo in
    // ...
}
```

**개선 방안:**

```swift
// TodoItem+Extensions.swift (새 파일)
import Foundation
import CoreData

extension TodoItem: Identifiable {
    // id 속성이 이미 CoreData에 정의되어 있으므로
    // 프로토콜 준수만 명시하면 됨
}

extension DiaryEntry: Identifiable {
    // 동일
}

// 사용 시 id 파라미터 생략 가능
ForEach(viewModel.todos) { todo in  // ✅ 더 간결
    TodoRowView(todo: todo) {
        viewModel.toggleCompletion(todo: todo)
    }
}
```

---

### 13. 햅틱 피드백 매니저

**현재 문제:**
- 햅틱 피드백 코드가 여러 곳에 중복됨

**개선 방안:**

```swift
// HapticManager.swift (새 파일)
import UIKit

enum HapticManager {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }

    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }

    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}

// 사용
Button(action: {
    onToggle()
    HapticManager.impact(.light)  // ✅ 간결
}) {
    // ...
}

// AddTodoSheet.swift
private func saveTodo() {
    let finalDueDate = hasDueDate ? dueDate : nil
    viewModel.addTodo(title: title, category: selectedCategory, dueDate: finalDueDate)

    HapticManager.notification(.success)  // ✅ 간결

    isPresented = false
}
```

---

## 📊 코드 품질 요약

| 항목 | 현재 상태 | 점수 | 개선 후 예상 |
|------|----------|------|------------|
| **아키텍처** | ✅ MVVM 패턴 적용 | 8/10 | 9/10 |
| **에러 처리** | ⚠️ 부족 | 4/10 | 8/10 |
| **성능** | ⚠️ 개선 필요 | 6/10 | 9/10 |
| **메모리 관리** | ⚠️ 누수 위험 | 5/10 | 9/10 |
| **코드 가독성** | ✅ 양호 | 8/10 | 9/10 |
| **테스트 가능성** | ❌ 테스트 없음 | 0/10 | 8/10 |
| **유지보수성** | ✅ 양호 | 7/10 | 9/10 |
| **접근성** | ⚠️ 미흡 | 3/10 | 8/10 |

**전체 평균:** 5.1/10 → **8.75/10** (예상)

---

## 🎯 우선순위 개선 로드맵

### Phase 1: 즉시 수정 (이번 주)

- [ ] **1. 자동 저장 디바운싱 수정**
  - 예상 시간: 30분
  - 영향도: 높음
  - `DiaryViewModel.scheduleSave()` 메서드 추가

- [ ] **2. 에러 처리 추가**
  - 예상 시간: 2시간
  - 영향도: 높음
  - ViewModel에 `errorMessage`, `showError` 추가
  - View에 `.alert()` 추가

- [ ] **3. DateFormatter 최적화**
  - 예상 시간: 30분
  - 영향도: 중간
  - static let으로 formatter 재사용

### Phase 2: 단기 개선 (1-2주)

- [ ] **4. 날짜 동기화 구조 개선**
  - 예상 시간: 3시간
  - 영향도: 중간
  - `DateManager` 클래스 생성 및 적용

- [ ] **5. List 높이 계산 개선**
  - 예상 시간: 1시간
  - 영향도: 낮음
  - 고정 높이 → maxHeight로 변경

- [ ] **6. 불필요한 파일 정리**
  - 예상 시간: 15분
  - 영향도: 낮음
  - 빈 파일 및 deprecated 파일 제거

- [ ] **7. Optional 처리 개선**
  - 예상 시간: 30분
  - 영향도: 낮음
  - "제목 없음" fallback 추가

### Phase 3: 중기 개선 (1개월)

- [ ] **8. CoreData fetch 최적화**
  - 예상 시간: 4시간
  - 영향도: 중간
  - NSFetchedResultsController 도입

- [ ] **9. 테스트 코드 작성**
  - 예상 시간: 2주
  - 영향도: 높음 (장기적)
  - Unit Tests 80% 커버리지 목표

- [ ] **10. 접근성 개선**
  - 예상 시간: 3시간
  - 영향도: 중간
  - VoiceOver 지원 추가

- [ ] **11. Preview 데이터 개선**
  - 예상 시간: 1시간
  - 영향도: 낮음
  - 다양한 시나리오 샘플 데이터

### Phase 4: 장기 개선 (2-3개월)

- [ ] **12. 성능 모니터링**
  - Instruments로 메모리 프로파일링
  - Launch time 최적화
  - 배터리 사용량 측정

- [ ] **13. CI/CD 구축**
  - GitHub Actions 설정
  - 자동 테스트 실행
  - 코드 커버리지 리포트

- [ ] **14. 문서화**
  - 아키텍처 문서
  - API 문서 (DocC)
  - 컨트리뷰션 가이드

---

## 📝 권장사항 요약

### 즉시 적용 권장 (Critical)

1. **디바운싱 로직 수정** - 메모리 누수 방지
2. **에러 처리 추가** - 사용자 경험 개선
3. **DateFormatter 최적화** - 성능 향상

### 곧 적용 권장 (High Priority)

4. **날짜 동기화 개선** - 버그 방지
5. **CoreData fetch 최적화** - 성능 향상
6. **테스트 코드 작성** - 품질 보증

### 향후 고려 (Medium Priority)

7. **접근성 개선** - 사용자층 확대
8. **빈 파일 정리** - 코드베이스 정리
9. **Preview 데이터 확장** - 개발 효율성

---

## 🔗 참고 자료

- [Apple - DateFormatter Performance](https://developer.apple.com/documentation/foundation/dateformatter)
- [Apple - Core Data Best Practices](https://developer.apple.com/documentation/coredata/core_data_best_practices)
- [Apple - Accessibility Guidelines](https://developer.apple.com/accessibility/)
- [SwiftUI Testing Best Practices](https://developer.apple.com/documentation/swiftui/testing-your-app)

---

## 변경 이력

- **2025-12-02**: 초기 코드 검토 완료
  - 12개 주요 이슈 식별
  - 우선순위별 로드맵 작성
  - 구체적인 개선 방안 제시

---

## 다음 단계

1. 이 문서를 팀과 공유
2. Phase 1 작업 시작 (즉시 수정 항목)
3. 각 개선 사항 구현 후 재검토
4. 테스트 코드 작성 시작
5. 정기적인 코드 리뷰 프로세스 수립

검토 완료 ✅
