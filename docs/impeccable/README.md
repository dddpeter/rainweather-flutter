# Impeccable Design Guidelines

前端设计最佳实践和反模式指南，源自 [impeccable](https://github.com/pbakaus/impeccable) 项目。

## 快速导航

### 核心设计原则

- **[色彩与对比度](color-and-contrast.md)** - OKLCH 色彩空间、调色板构建、无障碍对比度
- **[排版](typography.md)** - 字体系统、模块化比例、OpenType 特性
- **[空间设计](spatial-design.md)** - 间距系统、网格布局、视觉层次
- **[交互设计](interaction-design.md)** - 表单、焦点状态、加载模式
- **[响应式设计](responsive-design.md)** - 移动优先、流体设计、容器查询
- **[动效设计](motion-design.md)** - 缓动曲线、交错动画、减少运动偏好
- **[UX 文案](ux-writing.md)** - 按钮标签、错误消息、空状态

### 工作流程命令

- **[craft](craft.md)** - 完整的设计到代码流程
- **[shape](shape.md)** - 编写代码前的 UX/UI 规划
- **[critique](critique.md)** - UX 设计审查
- **[audit](audit.md)** - 技术质量检查（可访问性、性能）
- **[polish](polish.md)** - 最终优化和发布准备

### 设计改进

- **[bolder](bolder.md)** - 强化平淡的设计
- **[quieter](quieter.md)** - 简化过于复杂的设计
- **[distill](distill.md)** - 提炼到本质
- **[animate](animate.md)** - 添加有目的的动效
- **[colorize](colorize.md)** - 引入策略性色彩
- **[typeset](typeset.md)** - 修复字体选择
- **[layout](layout.md)** - 修复布局和间距
- **[delight](delight.md)** - 添加愉悦时刻

### 高级功能

- **[harden](harden.md)** - 错误处理、国际化、边界情况
- **[onboard](onboard.md)** - 首次使用流程、空状态
- **[adapt](adapt.md)** - 适配不同设备
- **[optimize](optimize.md)** - 性能优化
- **[extract](extract.md)** - 提取可复用组件
- **[clarify](clarify.md)** - 改进不清晰的 UX 文案
- **[overdrive](overdrive.md)** - 添加技术卓越的效果
- **[live](live.md)** - 浏览器中实时迭代 UI

### 项目管理

- **[teach](teach.md)** - 收集设计上下文，创建 PRODUCT.md 和 DESIGN.md
- **[document](document.md)** - 从现有代码生成 DESIGN.md

## 关键反模式（避免这些！）

### 1. 字体选择

- ❌ **不要使用** Arial, Inter, 系统默认字体
- ✅ **应该使用** 符合品牌个性的特色字体

### 2. 颜色使用

- ❌ **不要使用** 灰色文本在彩色背景上
- ❌ **不要使用** 纯黑色或纯灰色（总是添加色调）
- ❌ **不要过度使用** 紫色渐变（AI 设计的典型特征）
- ✅ **应该使用** OKLCH 色彩空间构建调色板

### 3. 卡片设计

- ❌ **不要** 把所有东西都放在卡片里
- ❌ **不要** 在卡片内嵌套卡片
- ✅ **应该使用** 留白和分隔线创造层次

### 4. 动效设计

- ❌ **不要使用** 弹跳/弹性缓动（显得过时）
- ✅ **应该使用** 自然的缓动曲线（ease-out, cubic-bezier）

### 5. 通用设计

- ❌ **不要** 所有项目使用相同的设计模板
- ✅ **应该** 根据品牌和产品类型定制设计

## 在 Flutter 项目中应用

### 1. 色彩系统

```dart
// 使用 OKLCH 概念定义颜色
class AppColors {
  // 主色调 - 基于品牌色
  static const Color primary = Color(0xFF6366F1); // Indigo

  // 中性色 - 带微量色调
  static const Color neutral50 = Color(0xFFF8FAFC);
  static const Color neutral100 = Color(0xFFF1F5F9);
  static const Color neutral900 = Color(0xFF0F172A);

  // 语义色
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
}
```

### 2. 间距系统

```dart
class AppSpacing {
  static const double xs = 4.0;   // 4px
  static const double sm = 8.0;   // 8px
  static const double md = 12.0;  // 12px
  static const double lg = 16.0;  // 16px
  static const double xl = 24.0;  // 24px
  static const double xxl = 32.0; // 32px
  static const double xxxl = 48.0;// 48px
}
```

### 3. 圆角规范

```dart
class AppRadius {
  static const double sm = 4.0;   // 小元素
  static const double md = 8.0;   // 卡片
  static const double lg = 12.0;  // 大卡片
  static const double xl = 16.0;  // 对话框
  static const double full = 9999.0; // 胶囊/圆形
}
```

### 4. 阴影层级

```dart
class AppShadows {
  static const BoxShadow sm = BoxShadow(
    color: Color(0x0A000000),
    offset: Offset(0, 1),
    blurRadius: 2,
  );

  static const BoxShadow md = BoxShadow(
    color: Color(0x14000000),
    offset: Offset(0, 2),
    blurRadius: 4,
  );

  static const BoxShadow lg = BoxShadow(
    color: Color(0x1E000000),
    offset: Offset(0, 4),
    blurRadius: 8,
  );
}
```

## 使用建议

### 日常开发

1. 参考 [color-and-contrast.md](color-and-contrast.md) 选择配色方案
2. 遵循 [spatial-design.md](spatial-design.md) 的间距规则
3. 查看 [interaction-design.md](interaction-design.md) 实现交互反馈

### 设计审查

1. 运行 `/impeccable audit` 检查技术问题
2. 运行 `/impeccable critique` 进行 UX 审查
3. 运行 `/impeccable polish` 做最后优化

### 重构改进

1. 运行 `/impeccable distill` 简化复杂界面
2. 运行 `/impeccable bolder` 强化平淡设计
3. 运行 `/impeccable animate` 添加微交互

## 相关资源

- [Impeccable 官方网站](https://impeccable.style)
- [GitHub 仓库](https://github.com/pbakaus/impeccable)
- [案例研究](https://impeccable.style#casestudies)

## 注意事项

> ⚠️ **重要**: 这些指南是通用原则，应根据具体项目需求灵活应用。始终优先考虑用户体验和业务目标。

---

_本指南基于 impeccable v2.1.7，最后更新于 2026-04-24_
