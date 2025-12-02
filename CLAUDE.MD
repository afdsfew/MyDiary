# MyDiary - iOS App

A SwiftUI-based diary and todo list application for iOS that helps users organize daily tasks and maintain journal entries.

## Project Overview

MyDiary is an iOS application that combines todo list management with diary/journaling functionality. Users can navigate through dates, manage daily tasks, and write journal entries for each day.

## Architecture

### Tech Stack
- **Framework**: SwiftUI
- **Platform**: iOS
- **Data Persistence**: CoreData
- **Language**: Swift

### Project Structure

```
MyDiary/
├── MyDiaryApp.swift           # App entry point
├── Persistence.swift          # CoreData stack configuration
├── ContentView.swift          # Deprecated legacy view (commented out)
├── Models/
│   ├── AppScreen.swift        # Screen navigation models
│   └── Enums/
│       ├── Category.swift     # Todo category enums
│       └── DateHelper.swift   # Date formatting utilities
├── Main/
│   ├── ViewModels/
│   │   ├── TodoViewModel.swift      # Todo list business logic
│   │   └── DiaryViewModel.swift     # Diary entry business logic
│   └── Views/
│       ├── MainView.swift           # Primary container view
│       ├── CalendarView.swift       # Calendar navigation
│       ├── TodoListView.swift       # Todo list display
│       ├── TodoRowView.swift        # Individual todo item
│       ├── AddTodoSheet.swift       # Todo creation sheet
│       └── DiaryEditorView.swift    # Diary text editor
└── MyDiary.xcodeproj/
```

## Key Features

### 1. Date Navigation
- Navigate between different dates using arrow buttons
- Quick access to today's date
- Date display with localized formatting
- Haptic feedback on date changes

### 2. Todo Management
- Create, read, update, and delete daily todos
- Categorize todos (via Category enum)
- Date-specific todo lists
- Interactive todo completion

### 3. Diary/Journal
- Write daily journal entries
- Date-specific diary entries
- Text editor for freeform writing

## Core Components

### MainView.swift
The primary container view that orchestrates the app's main functionality:
- Date header with navigation controls
- Todo list section
- Diary editor section
- Manages `TodoViewModel` and `DiaryViewModel`

### ViewModels
- **TodoViewModel**: Manages todo CRUD operations and date filtering
- **DiaryViewModel**: Handles diary entry creation and retrieval

### Data Models
- Uses CoreData for persistent storage
- Date-based data organization
- Category-based todo classification

## Development Notes

### CoreData Setup
- Managed through `PersistenceController.shared`
- Preview context available for SwiftUI previews
- ViewContext injected via environment

### UI/UX Features
- Navigation-based interface
- Responsive date selection
- Sectioned content layout
- System gray backgrounds for visual separation
- Haptic feedback on interactions

### Localization
- Korean language support ("오늘" button, etc.)
- DateHelper provides localized date formatting

## Getting Started

### Prerequisites
- Xcode (latest version recommended)
- iOS development environment
- Swift knowledge

### Building
1. Open `MyDiary.xcodeproj` in Xcode
2. Select target device/simulator
3. Build and run (Cmd+R)

### Testing
- SwiftUI previews available for most views
- Preview context uses `PersistenceController.preview`

## Code Conventions

### MVVM Pattern
The app follows Model-View-ViewModel architecture:
- **Models**: CoreData entities and enums
- **Views**: SwiftUI views
- **ViewModels**: Business logic and data management

### State Management
- `@StateObject` for ViewModels
- `@State` for local view state
- `@Binding` for parent-child data flow
- `@Environment` for CoreData context

## Future Considerations

Potential areas for enhancement:
- Search functionality across diary entries
- Todo filtering and sorting options
- Export/backup functionality
- Cloud sync capabilities
- Categories/tags for diary entries
- Reminders/notifications for todos

## Deprecated Code

`ContentView.swift` is kept for reference but is no longer active in the app. All functionality has been migrated to `MainView.swift`.
