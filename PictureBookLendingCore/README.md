# PictureBookLendingCore

A shared Swift Package Manager module for the PictureBookLendingApp that provides common domain models and services.

## Features

- Domain models: Book, User, Lending
- Services: BookService, LendingService

## Usage

### Adding to Your Project

1. In Xcode, select File > Add Package Dependencies...
2. Enter the package repository URL
3. Select the package and click Add Package

### Importing in Your Code

```swift
import PictureBookLendingCore

// Use the models
let book = Book(title: "My Book", author: "Author", isbn: "1234567890", publishedYear: 2025)

// Use the services
let bookService = BookService()
let books = bookService.getBooks()

let lendingService = LendingService()
let lending = lendingService.borrowBook(userId: userId, bookId: bookId)
```

### Adding to Workspace

To add this package to your workspace:

1. Open your workspace in Xcode
2. Select File > Add Packages...
3. Choose "Add Local..."
4. Select the PictureBookLendingCore directory
5. Click Add Package

Then, in your project's target settings:

1. Go to General > Frameworks, Libraries, and Embedded Content
2. Click the + button
3. Select PictureBookLendingCore
4. Click Add
