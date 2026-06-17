<div align="center">

[![Language](https://img.shields.io/badge/language-Racket-red)] [![License: MIT](https://img.shields.io/badge/license-MIT-green)](LICENSE)
  <h1>Taskly</h1>
  <p>A Simple and Intuitive Task Manager Built with Racket</p>

  <p><a href="README.md">English</a> | <a href="README.zh-CN.md">中文</a></p>
</div>

## Table of Contents

- [About](#about)
- [Features](#features)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
  - [Running the Application](#running-the-application)
- [Technical Architecture](#technical-architecture)
  - [Modular Design](#modular-design)
  - [Data Flow](#data-flow)
  - [Database Schema](#database-schema)
- [Development](#development)
  - [Running Tests](#running-tests)
  - [Code Structure](#code-structure)
  - [Debugging Tips](#debugging-tips)
- [Contributing](#contributing)
- [Deployment and Release](#deployment-and-release)
- [License](#license)

## About

Taskly is a simple and intuitive task management tool built with Racket. It provides a clean graphical interface for efficiently creating, organizing, and tracking tasks. Whether you're managing personal to-dos or team projects, Taskly helps you stay organized and focused.

For end-user documentation, please visit our [GitHub Pages](https://jrtxio.github.io/rtaskly).

## Features

- ✅ Create, edit, and delete tasks with ease
- 📋 Organize tasks into customizable lists
- 📅 Set due dates with smart shortcuts (e.g., "tomorrow", "next week")
- 🎯 Mark tasks as complete with visual feedback
- 💾 Automatic data persistence using SQLite
- 🌐 Cross-platform compatibility (Windows, macOS, Linux)
- 🎨 Simple and clean user interface
- 🌍 Multi-language support

## Getting Started

### Prerequisites

- Racket 8.0 or later
- Git

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/jrtxio/rtaskly.git
   cd rtaskly
   ```

2. **Build the application**
   - On Windows:
     ```powershell
     ./build.ps1
     ```
   - On macOS/Linux:
     ```bash
     ./build.sh
     ```

### Running the Application

```bash
racket src/taskly.rkt
```

## Technical Architecture

### Modular Design

Taskly follows a modular architecture with clear separation of concerns:

- **core/**: Core functionality including task management, list management, and database operations
  - `database.rkt`: SQLite database operations and schema management
  - `list.rkt`: Task list management (CRUD operations)
  - `task.rkt`: Task management (CRUD operations, due date handling)
  
- **gui/**: Graphical user interface components built with Racket GUI toolkit
  - `main-frame.rkt`: Main application window and layout
  - `sidebar.rkt`: Sidebar with list navigation
  - `task-panel.rkt`: Task display and management panel
  - `dialogs.rkt`: Dialog boxes for task and list operations
  - `language.rkt`: Multi-language support
  
- **utils/**: Utility functions for various operations
  - `date.rkt`: Date and time handling, including smart shortcut parsing
  - `path.rkt`: File path management and database file handling
  
- **tests/**: Comprehensive test suite
  - Unit tests for core functionality
  - Integration tests for end-to-end workflows
  - Edge case testing

### Data Flow

1. User interacts with GUI components
2. GUI events trigger core functionality calls
3. Core functions perform database operations via SQLite
4. Database changes are reflected in the GUI
5. All data is automatically persisted

### Database Schema

Taskly uses SQLite for data persistence with a simple schema:

```sql
-- Lists table
CREATE TABLE IF NOT EXISTS lists (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    created_at TEXT NOT NULL
);

-- Tasks table
CREATE TABLE IF NOT EXISTS tasks (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    description TEXT,
    due_date TEXT,
    completed INTEGER DEFAULT 0,
    list_id INTEGER,
    created_at TEXT NOT NULL,
    FOREIGN KEY (list_id) REFERENCES lists(id)
);
```

## Development

### Running Tests

Taskly has a comprehensive test suite to ensure functionality works as expected:

```bash
# Run all tests
racket tests/run-all-tests.rkt

# Run specific test files
racket tests/test-task.rkt
racket tests/test-list.rkt
```

### Code Structure

- All code follows Racket's style guide
- Modules are designed to be independent and testable
- Comments are used to explain complex logic
- Follow functional programming principles where appropriate

### Debugging Tips

- Use Racket's built-in debugger for GUI applications
- Enable verbose logging for database operations
- Test core functionality in isolation before GUI integration
- Use `displayln` for quick debugging output

## Contributing

Contributions are welcome! Whether you're reporting bugs, suggesting new features, or submitting code changes, we appreciate your help.

### Contribution Workflow

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/your-feature`)
3. Make your changes
4. Run the test suite to ensure everything works
5. Commit your changes with a descriptive message
6. Push to the branch (`git push origin feature/your-feature`)
7. Open a pull request

### Code Review Guidelines

- All changes must pass the test suite
- Code must follow the project's style guide
- Changes should be focused and minimal
- Add tests for new functionality
- Write clear commit messages

## Deployment and Release

### Build Process

1. Run the appropriate build script for your platform
2. The build process compiles the application and prepares distribution packages
3. Distribution packages are generated in the `dist/` directory

### Release Management

- Releases are managed through GitHub Releases
- Version numbers follow semantic versioning (MAJOR.MINOR.PATCH)
- Release notes are generated from commit messages

### CI/CD Configuration

- GitHub Actions are used for continuous integration
- Tests are run on every push to the main branch
- GitHub Pages are automatically deployed on every push to the main branch

## License

Taskly is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

---

<div align="center">
  <p>Built with Racket</p>
</div>
