import SwiftUI

struct DiaryEditorView: View {
    
    @ObservedObject var viewModel: DiaryViewModel
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 섹션 헤더
            HStack {
                Text("오늘의 메모")
                    .font(.system(size: 22, weight: .bold, design: .default))
                
                Spacer()
                
                // 마지막 저장 시간
                if let lastSaved = viewModel.lastSavedTime {
                    Text("저장됨 \(DateHelper.timeFormat(date: lastSaved))")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            // 메모 입력 영역
            ZStack(alignment: .topLeading) {
                // 플레이스홀더
                if viewModel.diaryContent.isEmpty {
                    Text("오늘 하루는 어땠나요?\n자유롭게 메모를 남겨보세요...")
                        .font(.system(size: 16))
                        .foregroundColor(.gray.opacity(0.5))
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                }
                
                // TextEditor
                TextEditor(text: $viewModel.diaryContent)
                    .font(.system(size: 16))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                    .onChange(of: viewModel.diaryContent) { oldValue, newValue in
                        // 자동 저장 (디바운싱)
                        viewModel.scheduleSave()
                    }
            }
            .frame(height: 250)
            .background(AppTheme.secondaryBackground(for: colorScheme))
            .cornerRadius(16)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(AppTheme.cardBackground(for: colorScheme))
        .cornerRadius(20)
        .shadow(color: AppTheme.shadowColor(for: colorScheme), radius: 10, x: 0, y: 4)
        .padding(.horizontal, 16)
    }
}
