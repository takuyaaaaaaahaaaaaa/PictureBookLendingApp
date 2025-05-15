# PictureBookLendingApp

## Project Structure

This is an iOS/macOS application built with SwiftUI and SwiftData, structured as a workspace with multiple projects:

- **PictureBookLendingApp.xcworkspace**: Main workspace containing all projects
  - **PictureBookLendingAdmin**: Admin application
  - **PictureBookLendingUser**: User application
  - **PictureBookLendingCore**: Shared core module (currently empty)

## Building and Running

### Prerequisites
- Xcode (latest version)
- macOS (latest version)

### Development Commands

#### Opening the Project
```bash
open PictureBookLendingApp.xcworkspace
```

#### Building and Running
1. Open the workspace in Xcode
2. Select the desired scheme (PictureBookLendingAdmin or PictureBookLendingUser)
3. Choose the target device/simulator
4. Press ⌘+R to build and run

#### Testing
1. Select the desired scheme
2. Press ⌘+U to run tests

## Architecture

The application follows a multi-module architecture:

- **PictureBookLendingUser**: End-user client application
- **PictureBookLendingAdmin**: Administrator client application
- **PictureBookLendingCore**: Intended for shared code and models (currently not implemented)

### Technology Stack

- **SwiftUI**: UI framework
- **SwiftData**: Persistence framework
- **Swift Package Manager**: Dependency management

### Data Model

Currently using a simple `Item` model with a timestamp property, implemented with SwiftData.

## Development Notes

- The project was recently converted from UIKit to SwiftUI
- The architecture was refactored to use a workspace with multiple targets
- SwiftData is being used for persistence
- Current implementation is minimal with placeholder views and models