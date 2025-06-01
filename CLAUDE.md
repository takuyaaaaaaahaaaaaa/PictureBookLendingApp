# PictureBookLendingApp

## Project Structure

This is an iOS/macOS application built with SwiftUI and SwiftData, structured as a workspace with multiple projects:

- **PictureBookLendingApp.xcworkspace**: Main workspace containing all projects
  - **PictureBookLendingAdmin**: Admin application
  - **PictureBookLendingDomain**: Domain module containing models and repository protocols

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
2. Select the PictureBookLendingAdmin scheme
3. Choose the target device/simulator
4. Press ⌘+R to build and run

#### Testing
1. Select the desired scheme
2. Press ⌘+U to run tests

## Architecture

The application follows a multi-module MV (Model-View) architecture:

- **PictureBookLendingAdmin**: Administrator client application
- **PictureBookLendingDomain**: Domain module with:
  - Observable models (BookModel, UserModel, LendingModel)
  - Domain entities (Book, User, Loan)
  - Repository protocols

### Technology Stack

- **SwiftUI**: UI framework
- **SwiftData**: Persistence framework
- **Swift Package Manager**: Dependency management
- **Observation**: For reactive models

### Data Model

The domain layer contains:
- **Entities**: Book, User, Loan
- **Observable Models**: BookModel, UserModel, LendingModel
- **Repository Protocols**: BookRepository, UserRepository, LoanRepository

## Development Notes

- The project follows MV architecture pattern inspired by Apple's Food Truck sample
- PictureBookLendingUser has been removed to focus on admin functionality
- Observable models are located in the Domain module, not the app layer
- RepositoryFactory remains in the app layer as it's an implementation detail
- SwiftData implementations are kept in the Admin app