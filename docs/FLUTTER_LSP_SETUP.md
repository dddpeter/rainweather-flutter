# Flutter LSP 安装状态

## ✅ LSP 已安装并可用

Flutter/Dart 的 Language Server Protocol (LSP) 已经包含在 Dart SDK 中，无需额外安装。

### 当前环境信息

- **Flutter 版本**: 3.41.4 (stable channel)
- **Dart 版本**: 3.11.1
- **LSP 服务器**: `dart language-server` ✅ 可用

### LSP 功能

Dart LSP 服务器提供以下功能：

1. **代码分析**
   - 实时错误和警告检测
   - 代码质量提示
   - 类型检查

2. **智能补全**
   - 代码自动补全
   - 参数提示
   - 导入建议

3. **重构工具**
   - 重命名变量/方法/类
   - 提取方法/变量
   - 组织导入

4. **导航功能**
   - 跳转到定义
   - 查找引用
   - 查看类型层次结构

5. **文档支持**
   - 悬停文档
   - 签名帮助
   - 代码片段

### 如何使用 LSP

#### 在 IDE 中（推荐）

大多数现代 IDE 已经内置了对 Dart LSP 的支持：

1. **VS Code**
   - 安装 "Dart" 扩展
   - 自动使用内置 LSP

2. **Android Studio / IntelliJ IDEA**
   - 安装 "Flutter" 和 "Dart" 插件
   - 自动使用内置 LSP

3. **其他编辑器**
   - Vim/Neovim: 使用 coc.nvim 或 nvim-lspconfig
   - Emacs: 使用 lsp-mode
   - Sublime Text: 使用 LSP 包

#### 命令行使用

```bash
# 启动 LSP 服务器（通常由 IDE 自动调用）
dart language-server

# 使用 LSP 协议（默认）
dart language-server --protocol=lsp

# 使用 Dart 分析服务器协议
dart language-server --protocol=analyzer

# 指定客户端信息
dart language-server --client-id="my-editor" --client-version="1.0.0"
```

#### 静态分析工具

```bash
# 分析整个项目
dart analyze

# 分析特定目录
dart analyze lib/

# 将 info 级别视为错误
dart analyze --fatal-infos
```

### 配置文件

项目可以创建 `analysis_options.yaml` 来自定义 LSP 行为：

```yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    - avoid_print
    - prefer_single_quotes
    - prefer_const_constructors
```

### 性能优化建议

1. **启用缓存**
   ```bash
   dart language-server --cache=/path/to/cache
   ```

2. **调试模式**（用于排查问题）
   ```bash
   dart language-server \
     --protocol-traffic-log=/tmp/lsp-traffic.log \
     --session-log=/tmp/lsp-session.log
   ```

3. **监控性能**
   ```bash
   dart language-server --diagnostic-port=9999
   # 然后在浏览器访问 http://localhost:9999
   ```

### 验证 LSP 工作正常

在项目目录运行：

```bash
# 1. 检查项目是否有分析错误
dart analyze

# 2. 查看 LSP 服务器版本
dart language-server --help

# 3. 在 IDE 中打开项目，应该能看到：
#    - 代码高亮
#    - 错误提示
#    - 自动补全
#    - 跳转定义等功能
```

## 常见问题

### Q: LSP 不工作怎么办？

1. 确保在项目根目录（包含 `pubspec.yaml` 的目录）
2. 运行 `flutter pub get` 安装依赖
3. 重启 IDE 或 LSP 服务器
4. 检查 `analysis_options.yaml` 配置

### Q: LSP 性能慢怎么办？

1. 检查项目大小，大型项目可能需要更多内存
2. 使用 `--cache` 参数启用缓存
3. 检查 `.gitignore` 中是否忽略了不必要的文件
4. 考虑拆分大型项目

### Q: 如何更新 LSP？

LSP 随 Dart SDK 一起更新：

```bash
# 更新 Flutter（会自动更新 Dart SDK）
flutter upgrade

# 或单独更新 Dart
brew upgrade dart
```

## 相关资源

- [Dart LSP 官方文档](https://github.com/dart-lang/sdk/tree/main/pkg/analysis_server)
- [Language Server Protocol 规范](https://microsoft.github.io/language-server-protocol)
- [Dart 分析服务器协议](https://dart.dev/go/analysis-server-protocol)

---
**安装日期**: 2026-03-13  
**Flutter 版本**: 3.41.4  
**Dart 版本**: 3.11.1
