import Foundation
import CoreData
import Combine

class DiaryViewModel: ObservableObject {
    
    @Published var diaryContent: String = ""
    @Published var selectedDate: Date = Date()
    @Published var lastSavedTime: Date?
    
    private let viewContext: NSManagedObjectContext
    private var currentDiary: DiaryEntry?
    
    init(context: NSManagedObjectContext) {
        self.viewContext = context
        loadDiary()
    }
    
    // MARK: - Load Diary
    
    /// 선택된 날짜의 일기를 불러옴
    func loadDiary() {
        let dayKey = DateHelper.dayKey(from: selectedDate)
        let request: NSFetchRequest<DiaryEntry> = DiaryEntry.fetchRequest()
        request.predicate = NSPredicate(format: "dayKey == %@", dayKey)
        request.fetchLimit = 1
        
        do {
            let results = try viewContext.fetch(request)
            if let diary = results.first {
                currentDiary = diary
                diaryContent = diary.content ?? ""
                lastSavedTime = diary.timestamp
            } else {
                currentDiary = nil
                diaryContent = ""
                lastSavedTime = nil
            }
        } catch {
            print("Failed to load diary: \(error)")
        }
    }
    
    // MARK: - Save Diary
    
    /// 일기 저장 (자동 저장)
    func saveDiary() {
        let dayKey = DateHelper.dayKey(from: selectedDate)
        
        // 빈 내용이면 기존 일기 삭제
        if diaryContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            if let diary = currentDiary {
                viewContext.delete(diary)
                currentDiary = nil
                lastSavedTime = nil
            }
        } else {
            // 기존 일기가 있으면 업데이트, 없으면 새로 생성
            if let diary = currentDiary {
                diary.content = diaryContent
                diary.timestamp = Date()
            } else {
                let newDiary = DiaryEntry(context: viewContext)
                newDiary.id = UUID()
                newDiary.content = diaryContent
                newDiary.dayKey = dayKey
                newDiary.timestamp = Date()
                currentDiary = newDiary
            }
            lastSavedTime = Date()
        }
        
        saveContext()
    }
    
    // MARK: - Date Selection
    
    /// 날짜 변경
    func selectDate(_ date: Date) {
        // 현재 일기 저장
        saveDiary()
        
        // 새 날짜로 변경
        selectedDate = date
        loadDiary()
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
