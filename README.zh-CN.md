<div align="center">
  <h1>Taskly</h1>
  <p>一个使用 Racket 构建的简单直观的任务管理工具</p>

  <p><a href="README.md">English</a> | <a href="README.zh-CN.md">中文</a></p>
</div>

## 目录

- [关于](#关于)
- [特性](#特性)
- [快速开始](#快速开始)
  - [前提条件](#前提条件)
  - [安装](#安装)
  - [运行应用](#运行应用)
- [技术架构](#技术架构)
  - [模块化设计](#模块化设计)
  - [数据流](#数据流)
  - [数据库架构](#数据库架构)
- [开发](#开发)
  - [运行测试](#运行测试)
  - [代码结构](#代码结构)
  - [调试技巧](#调试技巧)
- [贡献](#贡献)
- [部署与发布](#部署与发布)
- [许可证](#许可证)

## 关于

Taskly 是一个使用 Racket 构建的简单直观的任务管理工具。它提供了一个干净的图形界面，用于高效地创建、组织和跟踪任务。无论您是管理个人待办事项还是团队项目，Taskly 都能帮助您保持组织性和专注力。

对于最终用户文档，请访问我们的 [GitHub Pages](https://jrtxio.github.io/rtaskly)。

## 特性

- ✅ 轻松创建、编辑和删除任务
- 📋 将任务组织到自定义列表中
- 📅 使用智能快捷方式设置截止日期（例如，"明天"、"下周"）
- 🎯 标记任务为完成并获得视觉反馈
- 💾 使用 SQLite 自动持久化数据
- 🌐 跨平台兼容（Windows、macOS、Linux）
- 🎨 简单干净的用户界面
- 🌍 多语言支持

## 快速开始

### 前提条件

- Racket 8.0 或更高版本
- Git

### 安装

1. **克隆仓库**
   ```bash
   git clone https://github.com/jrtxio/rtaskly.git
   cd rtaskly
   ```

2. **构建应用程序**
   - 在 Windows 上：
     ```powershell
     ./build.ps1
     ```
   - 在 macOS/Linux 上：
     ```bash
     ./build.sh
     ```

### 运行应用

```bash
racket src/taskly.rkt
```

## 技术架构

### 模块化设计

Taskly 采用模块化架构，职责分明：

- **core/**：核心功能，包括任务管理、列表管理和数据库操作
  - `database.rkt`：SQLite 数据库操作和架构管理
  - `list.rkt`：任务列表管理（CRUD 操作）
  - `task.rkt`：任务管理（CRUD 操作、截止日期处理）
  
- **gui/**：使用 Racket GUI 工具包构建的图形用户界面组件
  - `main-frame.rkt`：主应用窗口和布局
  - `sidebar.rkt`：带有列表导航的侧边栏
  - `task-panel.rkt`：任务显示和管理面板
  - `dialogs.rkt`：用于任务和列表操作的对话框
  - `language.rkt`：多语言支持
  
- **utils/**：用于各种操作的工具函数
  - `date.rkt`：日期和时间处理，包括智能快捷方式解析
  - `path.rkt`：文件路径管理和数据库文件处理
  
- **tests/**：全面的测试套件
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

### 代码结构

- 所有代码遵循 Racket 的风格指南
- 模块设计为独立且可测试
- 使用注释解释复杂逻辑
- 尽可能遵循函数式编程原则

### 调试技巧

- 对 GUI 应用程序使用 Racket 的内置调试器
- 为数据库操作启用详细日志记录
- 在 GUI 集成之前隔离测试核心功能
- 使用 `displayln` 进行快速调试输出

## 贡献

欢迎贡献！无论您是报告错误、提出新功能建议还是提交代码更改，我们都非常感谢您的帮助。

### 贡献工作流程

1. Fork 仓库
2. 创建功能分支 (`git checkout -b feature/your-feature`)
3. 进行更改
4. 运行测试套件确保一切正常工作
5. 使用描述性消息提交更改
6. 推送到分支 (`git push origin feature/your-feature`)
7. 打开拉取请求

### 代码审查指南

- 所有更改必须通过测试套件
- 代码必须遵循项目的风格指南
- 更改应集中且最小化
- 为新功能添加测试
- 编写清晰的提交消息

## 部署与发布

### 构建流程

1. 为您的平台运行适当的构建脚本
2. 构建过程编译应用程序并准备分发包
3. 分发包在 `dist/` 目录中生成

### 发布管理

- 通过 GitHub Releases 管理发布
- 版本号遵循语义化版本控制（MAJOR.MINOR.PATCH）
- 发布说明从提交消息生成

### CI/CD 配置

- 使用 GitHub Actions 进行持续集成
- 每次推送到主分支时运行测试
- 每次推送到主分支时自动部署 GitHub Pages

## 许可证

Taskly 采用 MIT 许可证。详情请参阅 [LICENSE](LICENSE) 文件。

---

<div align="center">
  <p>使用 Racket 构建</p>
</div>