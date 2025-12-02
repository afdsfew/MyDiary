import Foundation
import Combine

/// 날짜 상태를 중앙에서 관리하는 ObservableObject
/// MainView, TodoViewModel, DiaryViewModel에서 공유하여 사용
class DateManager: ObservableObject {
    @Published var selectedDate: Date = Date()
}
