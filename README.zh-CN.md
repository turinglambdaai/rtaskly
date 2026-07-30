# Taskly

一个使用 **Noise** 构建的简单直观的任务管理工具 —— 它将 Racket 后端嵌入到原生 macOS（SwiftUI）应用中。后端拥有 SQLite 数据库，并将每个操作以带类型的 RPC 暴露出来；前端通过管道调用这些 RPC，因此所有任务逻辑都在后台运行，界面始终保持响应。

Taskly 提供了一个干净的图形界面 —— 参照 macOS 提醒事项设计 —— 用于高效地创建、组织和跟踪任务，无论您是管理个人待办事项还是团队项目。

![SwiftUI](https://img.shields.io/badge/SwiftUI-2396F3?logo=swift&logoColor=white) ![Racket](https://img.shields.io/badge/Racket-9F1D20?logo=racket&logoColor=white) [![License](https://img.shields.io/badge/license-MIT-blue)](LICENSE)

[English](README.md) · **中文**

## 功能特性

- **任务管理** —— 轻松创建、编辑和删除任务
- **可组织列表** —— 将任务分组到自定义列表中（默认创建 Work / Personal）
- **智能截止日期** —— 使用快捷方式设置截止日期：`+1d`、`@10am`、`@10am tomorrow`、`2025-08-07`
- **可视化完成** —— 标记任务为完成，带删除线和置灰样式
- **智能视图** —— 今天 / 计划 / 全部 / 完成，每个视图有独立的彩色列表图标
- **自动持久化** —— 数据使用 SQLite 本地存储
- **原生 macOS** —— 真正的 SwiftUI 应用，带提醒事项风格的侧边栏和列表面板
- **多语言** —— 中文 / 英文，可从菜单栏切换

## 环境要求

| 依赖 | 用途 / 版本 |
|------|------------|
| Racket | 9.x CS —— 编译后端 |
| [Noise](https://github.com/turinglambdaai/Noise) | Swift↔Racket 桥接（作为同级目录检出） |
| Xcode | Swift 6 / macOS 14 SDK |

## 快速开始

### 1. 克隆（将 Noise 作为同级目录）

```bash
git clone https://github.com/turinglambdaai/rtaskly.git
cd rtaskly
git clone https://github.com/turinglambdaai/Noise.git ../Noise
cd ../Noise && git lfs install && git lfs pull && cd ../rtaskly
make -C ../Noise/SwiftNoise        # 构建 RacketCS xcframework
raco pkg install --auto ../Noise/Racket/noise-serde-lib
```

### 2. 构建

```bash
make          # 编译 res/core.zo 并重新生成 Backend.swift
swift build   # 构建 macOS 应用
```

或使用一键脚本：

```bash
./bin/build --release
```

### 3. 运行

```bash
.build/debug/Taskly
```

> 每当修改任何 `taskly-core/*.rkt` 后，请重新运行 `make`，以确保
> `res/core.zo` 和 `Backend.swift` 保持同步。

## 技术架构

Taskly 基于 **Noise** 框架构建，该框架将 Racket CS 运行时嵌入到 Swift 应用中。应用分为 Racket 后端和 SwiftUI 前端，两者通过一对管道以带类型的二进制协议通信。

### 桥接如何工作

1. Racket 后端在 `taskly-core/` 中声明共享类型（`define-record`）和操作（`define-rpc`）；`main.rkt` 启动 Noise 的 `(serve in-fd out-fd)`。
2. `make` 通过 `raco ctool` 将 `main.rkt` 编译为自包含的 `res/core.zo`（运行时 + 所有模块字节码，包括 `db`/sqlite3），并通过 `raco noise-serde-codegen` 生成 Swift `Backend.swift` 客户端。
3. 应用嵌入 `core.zo`；`Backend.shared` 在后台线程启动 Racket 服务器，UI 调用 `async throws` 方法，参数通过管道封送。

`db` 库通过 FFI 加载系统 `libsqlite3`（macOS 自带），因此应用不需要附带额外的原生代码。

### 模块化设计

- **taskly-core/** —— Racket 后端（Noise RPC 服务器）
  - `main.rkt`：入口 —— `(main in-fd out-fd)` → `(serve ...)`
  - `rpc.rkt`：每个操作声明为 `define-rpc`
  - `types.rkt`：共享 serde 记录（`TaskItem`、`TodoList`）
  - `database.rkt`：SQLite 层和架构管理
  - `task.rkt` / `list.rkt`：任务和列表业务逻辑
  - `date.rkt` / `path.rkt`：日期解析器和 `~/.taskly` 路径

- **Taskly/** —— SwiftUI macOS 应用
  - `App/`：应用入口、`AppStore`（`@Observable`）、配置、设计令牌
  - `Backend/`：`Backend.shared` 单例
  - `Views/`：主窗口、侧边栏、任务面板、对话框
  - `Languages/`：中文 / 英文字符串目录
  - `Backend.swift`：生成的客户端 —— 请勿手动编辑；运行 `make`

- **tests/** —— 后端测试套件（日期解析、数据库 CRUD、RPC 接口）

### 数据流

1. 用户与 SwiftUI 界面交互
2. UI 操作调用 `Backend.shared` 上的异步方法
3. 调用通过管道封送到 Racket 服务器线程
4. 后端执行 SQLite 操作并返回结果
5. UI 通过 `@Observable` 重新渲染；所有数据自动持久化

### 数据库架构

Taskly 使用 SQLite，具有简单的架构：

```sql
-- 列表表
CREATE TABLE IF NOT EXISTS list (
    list_id   INTEGER PRIMARY KEY AUTOINCREMENT,
    list_name TEXT NOT NULL
);

-- 任务表
CREATE TABLE IF NOT EXISTS task (
    task_id      INTEGER PRIMARY KEY AUTOINCREMENT,
    list_id      INTEGER NOT NULL,
    task_text    TEXT NOT NULL,
    due_date     TEXT NULL,              -- "YYYY-MM-DD HH:MM" 或 NULL
    is_completed INTEGER NOT NULL DEFAULT 0,
    created_at   TEXT NOT NULL,          -- epoch 秒（字符串）
    FOREIGN KEY (list_id) REFERENCES list(list_id) ON DELETE CASCADE
);
```

## 开发

### 运行测试

后端有覆盖日期解析器、数据库层和 RPC/serde 接口的测试套件：

```bash
# 运行所有后端测试
raco test tests/

# 或通过入口点
racket run-tests.rkt
```

## 项目结构

```
rtaskly/
├── taskly-core/            # Racket 后端（Noise RPC 服务器）
│   ├── main.rkt            # 入口
│   ├── rpc.rkt             # define-rpc 接口
│   ├── types.rkt           # 共享 serde 记录
│   ├── database.rkt        # SQLite 层
│   ├── task.rkt / list.rkt # 业务逻辑
│   └── date.rkt / path.rkt # 日期解析器 + 路径
├── Taskly/                 # SwiftUI macOS 应用
│   ├── App/                # 入口、AppStore、配置、设计令牌
│   ├── Backend/            # Backend.shared 单例
│   ├── Views/              # 窗口、侧边栏、任务面板、对话框
│   ├── Languages/          # 中 / 英文字符串
│   └── Backend.swift       # 生成的客户端
├── tests/                  # 后端测试套件
├── Makefile                # core.zo + Backend.swift 流水线
├── Package.swift           # SPM 工程
└── bin/                    # 构建 / codegen 助手
```

## 许可证

基于 [MIT License](LICENSE) 开源。
