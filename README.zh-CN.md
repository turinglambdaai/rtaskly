# Taskly

一个使用 Racket 构建的简单直观的任务管理工具。它提供了一个干净的图形界面，用于高效地创建、组织和跟踪任务，无论您是管理个人待办事项还是团队项目。

对于最终用户文档，请访问 [GitHub Pages](https://turinglambdaai.github.io/rtaskly) 站点。

![Racket](https://img.shields.io/badge/Racket-9F1D20?logo=racket&logoColor=white) [![License](https://img.shields.io/badge/license-MIT-blue)](LICENSE)

[English](README.md) · **中文**

## 功能特性

- **任务管理** —— 轻松创建、编辑和删除任务
- **可组织列表** —— 将任务分组到自定义列表中
- **智能截止日期** —— 使用自然语言快捷方式设置截止日期（例如，"明天"、"下周"）
- **可视化完成** —— 标记任务为完成并获得视觉反馈
- **自动持久化** —— 数据使用 SQLite 存储
- **跨平台** —— 运行于 Windows、macOS 和 Linux
- **清爽界面** —— 简洁无杂乱的界面
- **多语言** —— 支持国际化

## 环境要求

| 依赖 | 用途 / 版本 |
|------|------------|
| Racket | 8.0 或更高版本 |
| Git | 版本控制 |

## 快速开始

### 1. 克隆仓库

```bash
git clone https://github.com/turinglambdaai/rtaskly.git
cd rtaskly
```

### 2. 构建

- 在 Windows 上：

  ```powershell
  ./build.ps1
  ```

- 在 macOS/Linux 上：

  ```bash
  ./build.sh
  ```

### 3. 运行

```bash
racket src/taskly.rkt
```

## 技术架构

### 模块化设计

Taskly 采用模块化架构，职责分明：

- **core/** —— 核心功能，包括任务管理、列表管理和数据库操作
  - `database.rkt`：SQLite 数据库操作和架构管理
  - `list.rkt`：任务列表管理（CRUD 操作）
  - `task.rkt`：任务管理（CRUD 操作、截止日期处理）

- **gui/** —— 使用 Racket GUI 工具包构建的图形用户界面组件
  - `main-frame.rkt`：主应用窗口和布局
  - `sidebar.rkt`：带有列表导航的侧边栏
  - `task-panel.rkt`：任务显示和管理面板
  - `dialogs.rkt`：用于任务和列表操作的对话框
  - `language.rkt`：多语言支持

- **utils/** —— 用于各种操作的工具函数
  - `date.rkt`：日期和时间处理，包括智能快捷方式解析
  - `path.rkt`：文件路径管理和数据库文件处理

- **tests/** —— 全面的测试套件
  - 核心功能的单元测试
  - 端到端工作流的集成测试
  - 边缘情况测试

### 数据流

1. 用户与 GUI 组件交互
2. GUI 事件触发核心功能调用
3. 核心函数通过 SQLite 执行数据库操作
4. 数据库更改反映在 GUI 中
5. 所有数据自动持久化

### 数据库架构

Taskly 使用 SQLite 进行数据持久化，具有简单的架构：

```sql
-- 列表表
CREATE TABLE IF NOT EXISTS lists (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    created_at TEXT NOT NULL
);

-- 任务表
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

## 开发

### 运行测试

Taskly 具有全面的测试套件，确保功能按预期工作：

```bash
# 运行所有测试
racket tests/run-all-tests.rkt

# 运行特定测试文件
racket tests/test-task.rkt
racket tests/test-list.rkt
```

### 调试技巧

- 对 GUI 应用程序使用 Racket 的内置调试器
- 为数据库操作启用详细日志记录
- 在 GUI 集成之前隔离测试核心功能
- 使用 `displayln` 进行快速调试输出

## 贡献

欢迎贡献！无论您是报告错误、提出新功能建议还是提交代码更改，我们都非常感谢您的帮助。

1. Fork 仓库
2. 创建功能分支 (`git checkout -b feature/your-feature`)
3. 进行更改
4. 运行测试套件确保一切正常工作
5. 使用描述性消息提交更改
6. 推送到分支 (`git push origin feature/your-feature`)
7. 打开拉取请求

## 部署与发布

- 构建过程编译应用程序并在 `dist/` 目录中准备分发包
- 通过 GitHub Releases 管理发布，遵循语义化版本控制（MAJOR.MINOR.PATCH）
- GitHub Actions 在每次推送到主分支时运行测试，并自动部署 GitHub Pages

## 项目结构

```
rtaskly/
├── src/
│   ├── taskly.rkt           # 应用入口
│   ├── core/                # 任务/列表管理和数据库操作
│   ├── gui/                 # GUI 组件（Racket GUI 工具包）
│   └── utils/               # 工具函数（日期、路径处理）
├── tests/                   # 全面的测试套件
├── build.sh                 # 构建脚本（macOS/Linux）
└── build.ps1                # 构建脚本（Windows）
```

## 许可证

基于 [MIT License](LICENSE) 开源。
