# Taskly

A simple and intuitive task manager built with **Noise** — it embeds a Racket backend inside a native macOS (SwiftUI) app. The backend owns the SQLite database and exposes every operation as a typed RPC; the frontend calls them over a pipe, so the UI stays responsive while all task logic runs in the background.

Taskly provides a clean graphical interface — modeled on macOS Reminders — for efficiently creating, organizing, and tracking tasks, whether you're managing personal to-dos or team projects.

![SwiftUI](https://img.shields.io/badge/SwiftUI-2396F3?logo=swift&logoColor=white) ![Racket](https://img.shields.io/badge/Racket-9F1D20?logo=racket&logoColor=white) [![License](https://img.shields.io/badge/license-MIT-blue)](LICENSE)

**English** · [中文](README.zh-CN.md)

## Features

- **Task management** — create, edit, and delete tasks with ease
- **Organizable lists** — group tasks into customizable lists (Work / Personal seeded by default)
- **Smart due dates** — set due dates with shortcuts: `+1d`, `@10am`, `@10am tomorrow`, `2025-08-07`
- **Visual completion** — mark tasks as complete with strikethrough + dimmed styling
- **Smart views** — Today / Scheduled / All / Completed, each with its own colored list icon
- **Automatic persistence** — data is stored locally using SQLite
- **Native macOS** — a real SwiftUI app with a Reminders-style sidebar and list pane
- **Multi-language** — Chinese / English, switchable from the menu bar

## Requirements

| Dependency | Purpose / Version |
|------------|-------------------|
| Racket | 9.x CS — to compile the backend |
| [Noise](https://github.com/turinglambdaai/Noise) | the Swift↔Racket bridge (checked out as a sibling) |
| Xcode | Swift 6 / macOS 14 SDK |

## Quick Start

### 1. Clone (with Noise as a sibling)

```bash
git clone https://github.com/turinglambdaai/rtaskly.git
cd rtaskly
git clone https://github.com/turinglambdaai/Noise.git ../Noise
cd ../Noise && git lfs install && git lfs pull && cd ../rtaskly
make -C ../Noise/SwiftNoise        # build the RacketCS xcframeworks
raco pkg install --auto ../Noise/Racket/noise-serde-lib
```

### 2. Build

```bash
make          # compiles res/core.zo and regenerates Backend.swift
swift build   # builds the macOS app
```

Or the one-shot helper:

```bash
./bin/build --release
```

### 3. Run

```bash
.build/debug/Taskly
```

> Rerun `make` whenever you change any `taskly-core/*.rkt`, so both
> `res/core.zo` and `Backend.swift` stay in sync.

## Technical Architecture

Taskly is built on the **Noise** framework, which embeds the Racket CS runtime into Swift applications. The app is split into a Racket backend and a SwiftUI frontend that communicate over a pair of pipes with a typed binary protocol.

### How the bridge works

1. The Racket backend declares shared types (`define-record`) and operations (`define-rpc`) in `taskly-core/`; `main.rkt` boots Noise's `(serve in-fd out-fd)`.
2. `make` compiles `main.rkt` into a self-contained `res/core.zo` (runtime + all module bytecode, including `db`/sqlite3) via `raco ctool`, and generates the Swift `Backend.swift` client via `raco noise-serde-codegen`.
3. The app embeds `core.zo`; `Backend.shared` boots the Racket server on a background thread, and the UI calls `async throws` methods that marshal arguments over the pipes.

The `db` library loads the system `libsqlite3` via FFI (bundled with macOS), so no extra native code ships with the app.

### Modular Design

- **taskly-core/** — the Racket backend (Noise RPC server)
  - `main.rkt`: entry point — `(main in-fd out-fd)` → `(serve ...)`
  - `rpc.rkt`: every operation declared as a `define-rpc`
  - `types.rkt`: shared serde records (`TaskItem`, `TodoList`)
  - `database.rkt`: SQLite layer and schema management
  - `task.rkt` / `list.rkt`: task and list business logic
  - `date.rkt` / `path.rkt`: the date parser and `~/.taskly` paths

- **Taskly/** — the SwiftUI macOS app
  - `App/`: app entry, `AppStore` (`@Observable`), config, design tokens
  - `Backend/`: the `Backend.shared` singleton
  - `Views/`: main window, sidebar, task panel, dialogs
  - `Languages/`: the Chinese / English string catalog
  - `Backend.swift`: generated client — do not edit; run `make`

- **tests/** — the backend test suite (date parsing, database CRUD, RPC surface)

### Data Flow

1. The user interacts with the SwiftUI interface
2. UI actions call async methods on `Backend.shared`
3. Calls are marshaled over a pipe to the Racket server thread
4. The backend performs SQLite operations and returns the result
5. The UI re-renders via `@Observable`; all data is automatically persisted

### Database Schema

Taskly uses SQLite with a simple schema:

```sql
-- Lists
CREATE TABLE IF NOT EXISTS list (
    list_id   INTEGER PRIMARY KEY AUTOINCREMENT,
    list_name TEXT NOT NULL
);

-- Tasks
CREATE TABLE IF NOT EXISTS task (
    task_id      INTEGER PRIMARY KEY AUTOINCREMENT,
    list_id      INTEGER NOT NULL,
    task_text    TEXT NOT NULL,
    due_date     TEXT NULL,              -- "YYYY-MM-DD HH:MM" or NULL
    is_completed INTEGER NOT NULL DEFAULT 0,
    created_at   TEXT NOT NULL,          -- epoch seconds as string
    FOREIGN KEY (list_id) REFERENCES list(list_id) ON DELETE CASCADE
);
```

## Development

### Running Tests

The backend has a test suite covering the date parser, the database layer, and the RPC/serde surface:

```bash
# Run all backend tests
raco test tests/

# Or via the entry point
racket run-tests.rkt
```

## Project Structure

```
rtaskly/
├── taskly-core/            # Racket backend (Noise RPC server)
│   ├── main.rkt            # entry point
│   ├── rpc.rkt             # define-rpc surface
│   ├── types.rkt           # shared serde records
│   ├── database.rkt        # SQLite layer
│   ├── task.rkt / list.rkt # business logic
│   └── date.rkt / path.rkt # date parser + paths
├── Taskly/                 # SwiftUI macOS app
│   ├── App/                # entry, AppStore, config, design tokens
│   ├── Backend/            # Backend.shared singleton
│   ├── Views/              # window, sidebar, task panel, dialogs
│   ├── Languages/          # zh / en strings
│   └── Backend.swift       # GENERATED client
├── tests/                  # backend test suite
├── Makefile                # core.zo + Backend.swift pipeline
├── Package.swift           # SPM project
└── bin/                    # build / codegen helpers
```

## License

Licensed under the [MIT License](LICENSE).
