# MyDiary 테스트 커버리지 분석

> 작성일: 2025-12-02
> 분석 도구: Claude Code

## 요약

코드베이스를 분석한 결과, **현재 프로젝트에 테스트 파일이 전혀 없습니다**. 이 SwiftUI 다이어리 앱에는 테스트가 필요한 여러 컴포넌트들이 있습니다.

---

## 현재 코드베이스 구조

### ViewModels
- `TodoViewModel.swift` - Todo 항목 CRUD 관리
- `DiaryViewModel.swift` - 일기 저장 및 자동 저장 처리

### Models/Utilities
- `DateHelper.swift` - 날짜 포맷팅 및 조작 유틸리티
- `Category.swift` - 카테고리 열거형 및 UI 속성
- CoreData 엔티티: `TodoItem`, `DiaryEntry`

### Views
- `MainView.swift` - 메인 화면 구성
- `TodoListView.swift` - Todo 리스트 표시
- `TodoRowView.swift` - Todo 개별 행
- `AddTodoSheet.swift` - Todo 추가 시트
- `DiaryEditorView.swift` - 일기 에디터
- `CalendarView.swift` - 달력 뷰

---

## 테스트 개선이 필요한 우선순위 영역

### 🔴 최우선 순위

#### 1. TodoViewModel 테스트
**파일:** `TodoViewModel.swift:1-117`
**중요한 이유:** CoreData 작업을 포함한 핵심 비즈니스 로직 포함

**권장 테스트:**
- `test_addTodo_올바른속성으로새Todo생성()`
  - 제목, 카테고리, 마감일이 올바르게 설정되는지 확인
  - dayKey가 선택된 날짜로 설정되는지 확인
  - isCompleted가 false로 초기화되는지 확인

- `test_toggleCompletion_완료상태토글()`
  - 미완료 항목이 완료로 변경되는지 확인
  - 완료 항목이 미완료로 변경되는지 확인

- `test_deleteTodo_컨텍스트에서Todo제거()`
  - 삭제 후 todos 배열에서 제거되는지 확인
  - CoreData에서 실제로 삭제되는지 확인

- `test_fetchTodos_올바른DayKey필터링()`
  - 선택된 날짜의 항목만 가져오는지 확인
  - 다른 날짜의 항목은 제외되는지 확인

- `test_fetchTodos_완료된항목먼저정렬()`
  - 미완료 항목이 먼저 나오는지 확인
  - 같은 상태 내에서 생성일 순 정렬되는지 확인

- `test_completedCount_올바른개수반환()`
  - 완료된 항목 수를 정확히 계산하는지 확인

- `test_totalCount_올바른개수반환()`
  - 전체 항목 수를 정확히 반환하는지 확인

- `test_selectDate_선택날짜업데이트및Todo새로고침()`
  - 날짜 변경 시 selectedDate가 업데이트되는지 확인
  - 새 날짜의 todos가 로드되는지 확인

- `test_updateTodo_모든속성업데이트()`
  - 제목, 카테고리, 마감일이 모두 업데이트되는지 확인

- `test_deleteTodos_IndexSet으로여러항목삭제()`
  - IndexSet으로 여러 항목을 동시에 삭제할 수 있는지 확인

---

#### 2. DiaryViewModel 테스트
**파일:** `DiaryViewModel.swift:1-97`
**중요한 이유:** 자동 저장 및 날짜 전환 로직을 가진 일기 저장 관리

**권장 테스트:**
- `test_loadDiary_날짜별기존일기로드()`
  - 해당 날짜의 일기가 있으면 로드되는지 확인
  - diaryContent가 올바르게 설정되는지 확인
  - lastSavedTime이 설정되는지 확인

- `test_loadDiary_일기없을때빈값반환()`
  - 일기가 없으면 빈 문자열이 반환되는지 확인
  - currentDiary가 nil로 설정되는지 확인

- `test_saveDiary_새항목생성()`
  - 새 일기가 CoreData에 저장되는지 확인
  - UUID가 생성되는지 확인
  - dayKey가 올바르게 설정되는지 확인

- `test_saveDiary_기존항목업데이트()`
  - 기존 일기의 내용이 업데이트되는지 확인
  - timestamp가 업데이트되는지 확인
  - 새 항목이 생성되지 않는지 확인

- `test_saveDiary_내용비었을때항목삭제()`
  - 빈 내용으로 저장 시 일기가 삭제되는지 확인
  - currentDiary가 nil로 설정되는지 확인
  - lastSavedTime이 nil로 설정되는지 확인

- `test_selectDate_로드전이전일기저장()`
  - 날짜 변경 시 현재 일기가 먼저 저장되는지 확인
  - 새 날짜의 일기가 로드되는지 확인

- `test_lastSavedTime_저장후업데이트()`
  - saveDiary() 호출 후 lastSavedTime이 업데이트되는지 확인

---

#### 3. DateHelper 테스트
**파일:** `DateHelper.swift:1-54`
**중요한 이유:** 날짜 조작은 오류가 발생하기 쉽고 앱 전체에서 사용됨

**권장 테스트:**
- `test_dayKey_올바른포맷반환()`
  - "yyyy-MM-dd" 형식으로 반환되는지 확인
  - 예: 2025년 12월 2일 → "2025-12-02"

- `test_date_dayKey에서올바른날짜반환()`
  - dayKey 문자열을 Date로 변환하는지 확인

- `test_date_잘못된포맷시nil반환()`
  - 잘못된 형식의 문자열에 대해 nil 반환 확인

- `test_displayFormat_올바른한국어포맷반환()`
  - "M월 d일 (E)" 형식으로 반환되는지 확인
  - 한국어 로케일이 적용되는지 확인

- `test_timeFormat_올바른시분포맷반환()`
  - "HH:mm" 형식으로 반환되는지 확인

- `test_startOfDay_자정반환()`
  - 해당 날짜의 00:00:00 반환 확인

- `test_isSameDay_같은날true반환()`
  - 같은 날의 다른 시간이 같은 날로 인식되는지 확인

- `test_isSameDay_다른날false반환()`
  - 다른 날짜가 다른 날로 인식되는지 확인

- `test_isToday_오늘true반환()`
  - 오늘 날짜에 대해 true 반환 확인

- `test_isToday_다른날false반환()`
  - 과거/미래 날짜에 대해 false 반환 확인

---

### 🟡 중간 우선순위

#### 4. CoreData 통합 테스트
**중요한 이유:** 데이터 영속성이 올바르게 작동하는지 확인

**권장 테스트:**
- `test_todoItem_데이터베이스에저장()`
  - TodoItem이 CoreData에 저장되는지 확인
  - 저장 후 fetch로 다시 가져올 수 있는지 확인

- `test_diaryEntry_데이터베이스에저장()`
  - DiaryEntry가 CoreData에 저장되는지 확인

- `test_fetchRequest_조건자로필터링된결과반환()`
  - NSPredicate가 올바르게 작동하는지 확인
  - dayKey로 필터링이 정확한지 확인

- `test_deleteOperation_데이터베이스에서항목제거()`
  - 삭제 후 다시 fetch 시 항목이 없는지 확인

- `test_updateOperation_기존항목수정()`
  - 수정 후 저장 시 변경사항이 유지되는지 확인

- `test_multipleItems_같은DayKey로그룹화()`
  - 같은 날짜의 여러 항목이 함께 조회되는지 확인

---

#### 5. Category Enum 테스트
**파일:** `Category.swift:1-34`
**중요한 이유:** UI 속성이 올바르게 할당되었는지 검증

**권장 테스트:**
- `test_allCategories_고유한색상보유()`
  - 각 카테고리가 고유한 색상을 가지는지 확인

- `test_allCategories_유효한아이콘보유()`
  - 각 카테고리가 유효한 SF Symbol 아이콘을 가지는지 확인

- `test_categoryRawValues_올바른한국어텍스트()`
  - 공부, 개인, 과제, 기타 텍스트가 올바른지 확인

- `test_allCases_네가지카테고리모두포함()`
  - Category.allCases가 4개의 항목을 포함하는지 확인

---

### 🟢 낮은 우선순위

#### 6. UI 테스트
**유용한 이유:** 사용자 플로우가 종단간 작동하는지 확인

**권장 테스트:**
- `testUI_todo추가_리스트에새todo생성()`
  - + 버튼 탭 → 시트 열림 → 정보 입력 → 저장 → 리스트에 표시

- `testUI_todo완료토글_체크마크업데이트()`
  - 체크박스 탭 시 UI가 업데이트되는지 확인

- `testUI_todo삭제_리스트에서제거()`
  - 스와이프 삭제 또는 편집 모드 삭제 확인

- `testUI_날짜네비게이션_올바른날짜데이터로드()`
  - 날짜 변경 버튼 탭 시 올바른 데이터 로드 확인

- `testUI_일기자동저장_지연후저장()`
  - 타이핑 후 1초 후 자동 저장 확인

- `testUI_빈상태_todo없을때표시()`
  - 빈 상태 메시지와 아이콘이 표시되는지 확인

---

#### 7. ViewModel 에러 처리 테스트
**유용한 이유:** 우아한 실패 처리 검증

**권장 테스트:**
- `test_saveContext_실패시우아하게처리()`
  - CoreData 저장 실패 시 앱이 크래시하지 않는지 확인

- `test_fetchTodos_손상된데이터우아하게처리()`
  - 잘못된 데이터가 있어도 앱이 작동하는지 확인

- `test_invalidDayKey_적절히처리()`
  - 잘못된 dayKey 형식에 대한 처리 확인

---

## 권장 테스트 파일 구조

```
MyDiary/
├── MyDiary/
│   └── (기존 소스 코드)
├── MyDiaryTests/
│   ├── ViewModels/
│   │   ├── TodoViewModelTests.swift
│   │   └── DiaryViewModelTests.swift
│   ├── Models/
│   │   ├── DateHelperTests.swift
│   │   └── CategoryTests.swift
│   ├── Persistence/
│   │   └── CoreDataTests.swift
│   └── Integration/
│       └── DataFlowIntegrationTests.swift
└── MyDiaryUITests/
    └── MyDiaryUITests.swift
```

---

## 테스트로 해결해야 할 코드 품질 문제

### 1. 에러 처리 개선 필요
**위치:** `TodoViewModel.swift:32-33`, `DiaryViewModel.swift:40-41`

**현재 문제:**
```swift
} catch {
    print("Failed to fetch todos: \(error)")
}
```

현재 에러는 콘솔에만 출력되고 사용자에게 알려지지 않습니다.

**테스트로 검증해야 할 사항:**
- 적절한 에러 전파
- 사용자 대상 에러 메시지
- 우아한 성능 저하 (graceful degradation)

**개선 방향:**
```swift
@Published var errorMessage: String?

func fetchTodos() {
    // ...
    do {
        todos = try viewContext.fetch(request)
        errorMessage = nil
    } catch {
        print("Failed to fetch todos: \(error)")
        errorMessage = "할 일을 불러오는데 실패했습니다."
        todos = [] // 빈 배열로 초기화
    }
}
```

---

### 2. 자동 저장 디바운싱 로직
**위치:** `DiaryEditorView.swift:42-45`

**현재 구현:**
```swift
.onChange(of: viewModel.diaryContent) { oldValue, newValue in
    // 자동 저장 (디바운싱)
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
        viewModel.saveDiary()
    }
}
```

**문제점:**
- 매 글자마다 1초 타이머가 새로 생성됨
- 이전 타이머가 취소되지 않음
- 빠르게 타이핑하면 여러 번 저장될 수 있음

**테스트해야 할 사항:**
- 모든 키 입력마다 저장이 발생하지 않는지 확인
- 타이핑 중단 후 정확히 1초 후 저장되는지 확인
- 빠른 날짜 전환 시 데이터 손실이 없는지 테스트

**개선 방향:**
```swift
class DiaryViewModel: ObservableObject {
    private var saveTask: Task<Void, Never>?

    func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            if !Task.isCancelled {
                saveDiary()
            }
        }
    }
}
```

---

### 3. CoreData 컨텍스트 관리
**위치:** `Persistence.swift:49-62`

**현재 문제:**
```swift
if let error = error as NSError? {
    fatalError("Unresolved error \(error), \(error.userInfo)")
}
```

`fatalError()`는 앱을 강제 종료시킵니다. 프로덕션 환경에서는 적절하지 않습니다.

**테스트 및 개선 방향:**
- 테스트 환경에서 에러 핸들링 검증
- 프로덕션 환경에서는 에러 로깅 및 사용자 알림
- 인메모리 스토어로 폴백 옵션 제공

---

## 테스트 작성 가이드

### 인메모리 CoreData 설정 예제

```swift
import XCTest
import CoreData
@testable import MyDiary

class TodoViewModelTests: XCTestCase {

    var viewModel: TodoViewModel!
    var context: NSManagedObjectContext!

    override func setUp() {
        super.setUp()

        // 인메모리 CoreData 스택 생성
        let container = NSPersistentContainer(name: "MyDiary")
        container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        container.loadPersistentStores { _, error in
            XCTAssertNil(error)
        }

        context = container.viewContext
        viewModel = TodoViewModel(context: context)
    }

    override func tearDown() {
        viewModel = nil
        context = nil
        super.tearDown()
    }

    func test_addTodo_올바른속성으로새Todo생성() {
        // Given
        let title = "테스트 할 일"
        let category = Category.study
        let dueDate = Date()

        // When
        viewModel.addTodo(title: title, category: category, dueDate: dueDate)

        // Then
        XCTAssertEqual(viewModel.todos.count, 1)
        XCTAssertEqual(viewModel.todos.first?.title, title)
        XCTAssertEqual(viewModel.todos.first?.category, category.rawValue)
        XCTAssertFalse(viewModel.todos.first?.isCompleted ?? true)
    }
}
```

---

## 다음 단계

### 1단계: XCTest 타겟 추가
1. Xcode에서 File → New → Target
2. iOS Unit Testing Bundle 선택
3. 타겟 이름: `MyDiaryTests`

### 2단계: DateHelper 테스트 먼저 구현
- 가장 쉽게 테스트 가능한 순수 함수
- CoreData 의존성 없음
- 빠른 성공 경험 확보

### 3단계: ViewModel 테스트 추가
- 인메모리 CoreData 사용
- 높은 영향력의 비즈니스 로직 검증

### 4단계: CI/CD 설정
- GitHub Actions 또는 Xcode Cloud 설정
- 테스트 커버리지 리포트 자동 생성
- PR마다 테스트 자동 실행

### 5단계: 커버리지 목표 설정
- ViewModel: 80%+ 커버리지 목표
- Utilities: 90%+ 커버리지 목표
- Views: UI 테스트로 주요 플로우 커버

---

## 참고 자료

- [XCTest - Apple Developer](https://developer.apple.com/documentation/xctest)
- [Testing Core Data - Apple Developer](https://developer.apple.com/documentation/coredata/testing_core_data)
- [SwiftUI Testing Best Practices](https://developer.apple.com/documentation/swiftui/testing-your-app)

---

## 변경 이력

- 2025-12-02: 초기 테스트 커버리지 분석 완료
