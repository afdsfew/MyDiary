import SwiftUI

struct SettingsView: View {
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("themeMode") private var themeMode: String = ThemeMode.system.rawValue
    
    private var currentThemeMode: ThemeMode {
        ThemeMode(rawValue: themeMode) ?? .system
    }
    
    var body: some View {
        NavigationView {
            List {
                // 테마 설정
                Section(header: Text("테마")) {
                    ForEach(ThemeMode.allCases, id: \.self) { mode in
                        Button(action: {
                            themeMode = mode.rawValue
                            // 햅틱 피드백
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                        }) {
                            HStack {
                                Image(systemName: mode.icon)
                                    .foregroundColor(currentThemeMode == mode ? .blue : .secondary)
                                    .frame(width: 30)
                                
                                Text(mode.rawValue)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                if currentThemeMode == mode {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
                
                // 앱 정보
                Section(header: Text("앱 정보")) {
                    HStack {
                        Text("버전")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("개발자")
                        Spacer()
                        Text("MyDiary Team")
                            .foregroundColor(.secondary)
                    }
                }
                
                // 데이터 관리
                Section(header: Text("데이터")) {
                    Button(action: {
                        // TODO: 데이터 내보내기 기능
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("데이터 내보내기")
                        }
                    }
                    
                    Button(action: {
                        // TODO: 데이터 초기화 기능
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("모든 데이터 삭제")
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("설정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("완료") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
