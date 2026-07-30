# Taskly

A simple and intuitive task manager built with Racket. It provides a clean graphical interface for efficiently creating, organizing, and tracking tasks, whether you're managing personal to-dos or team projects.

For end-user documentation, please visit the [GitHub Pages](https://turinglambdaai.github.io/rtaskly) site.

![Racket](https://img.shields.io/badge/Racket-9F1D20?logo=racket&logoColor=white) [![License](https://img.shields.io/badge/license-MIT-blue)](LICENSE)

**English** · [中文](README.zh-CN.md)

## Features

- **Task management** — create, edit, and delete tasks with ease
- **Organizable lists** — group tasks into customizable lists
- **Smart due dates** — set due dates with natural shortcuts (e.g., "tomorrow", "next week")
- **Visual completion** — mark tasks as complete with visual feedback
- **Automatic persistence** — data is stored using SQLite
- **Cross-platform** — runs on Windows, macOS, and Linux
- **Clean UI** — simple and uncluttered interface
- **Multi-language** — internationalization support

## Requirements

| Dependency | Purpose / Version |
|------------|-------------------|
| Racket | 8.0 or later |
| Git | Source control |

## Quick Start

### 1. Clone

```bash
git clone https://github.com/turinglambdaai/rtaskly.git
cd rtaskly
```

### 2. Build

- On Windows:

  ```powershell
  ./build.ps1
  ```

- On macOS/Linux:

  ```bash
  ./build.sh
  ```

### 3. Run

```bash
racket src/taskly.rkt
```

## Technical Architecture

### Modular Design

Taskly follows a modular architecture with clear separation of concerns:

- **core/** — core functionality including task management, list management, and database operations
  - `database.rkt`: SQLite database operations and schema management
  - `list.rkt`: Task list management (CRUD operations)
  - `task.rkt`: Task management (CRUD operations, due date handling)

- **gui/** — graphical user interface components built with Racket GUI toolkit
  - `main-frame.rkt`: Main application window and layout
  - `sidebar.rkt`: Sidebar with list navigation
  - `task-panel.rkt`: Task display and management panel
  - `dialogs.rkt`: Dialog boxes for task and list operations
  - `language.rkt`: Multi-language support

- **utils/** — utility functions for various operations
  - `date.rkt`: Date and time handling, including smart shortcut parsing
  - `path.rkt`: File path management and database file handling

- **tests/** — comprehensive test suite
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

### Debugging Tips

- Use Racket's built-in debugger for GUI applications
- Enable verbose logging for database operations
- Test core functionality in isolation before GUI integration
- Use `displayln` for quick debugging output

## Contributing

Contributions are welcome! Whether you're reporting bugs, suggesting new features, or submitting code changes, we appreciate your help.

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/your-feature`)
3. Make your changes
4. Run the test suite to ensure everything works
5. Commit your changes with a descriptive message
6. Push to the branch (`git push origin feature/your-feature`)
7. Open a pull request

## Deployment and Release

- Build process compiles the application and prepares distribution packages in the `dist/` directory
- Releases are managed through GitHub Releases and follow semantic versioning (MAJOR.MINOR.PATCH)
- GitHub Actions run tests on every push to the main branch and auto-deploy GitHub Pages

## Project Structure

```
rtaskly/
├── src/
│   ├── taskly.rkt           # Application entry point
│   ├── core/                # Task/list management and database operations
│   ├── gui/                 # GUI components (Racket GUI toolkit)
│   └── utils/               # Utilities (date, path handling)
├── tests/                   # Comprehensive test suite
├── build.sh                 # Build script (macOS/Linux)
└── build.ps1                # Build script (Windows)
```

## License

Licensed under the [MIT License](LICENSE).
