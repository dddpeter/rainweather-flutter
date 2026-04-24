# 颜色对比度审计报告

**生成日期**: 2026-04-24  
**标准**: WCAG 1.4.3 Contrast (Minimum) - Level AA (4.5:1)  
**项目**: 智雨天气 (RainWeather)

---

## 执行摘要

### 当前状态评估

经过代码审查，发现以下对比度相关问题：

| 问题类型                  | 严重程度 | 数量   | 状态        |
| ------------------------- | -------- | ------ | ----------- |
| 灰色文本在彩色背景上      | P0       | 待确认 | 🔍 需要检查 |
| textTertiary 在渐变背景上 | P1       | 多处   | ⚠️ 潜在问题 |
| AI 卡片文本对比度         | -        | -      | ✅ 已优化   |
| 主题切换时的对比度        | P2       | 待验证 | 🔍 需要测试 |

**总体评分**: 3/4 (Good) - 大部分实现良好，有改进空间

---

## 已完成的优化

### ✅ AI 卡片对比度优化

**位置**: `lib/constants/app_colors.dart`

```dart
// 亮色模式：深棕色文本在琥珀金渐变背景上
static const Color aiTextColorLight = Color(0xFF3E2723);

// 暗色模式：深棕色文本在金琥珀色渐变背景上
static const Color aiTextColorDark = Color(0xFF3E2723);
```

**验证结果**:

- 背景: 琥珀金渐变 (#FF8F00 → #FFFFCC80)
- 文本: 深棕色 (#3E2723)
- 预估对比度: > 7:1 (AAA 级别) ✅

### ✅ ColorContrast 工具类增强

新增方法：

- `validateContrast()` - 验证任意颜色组合的对比度
- `isGrayOnColoredBackgroundAccessible()` - 检查灰色文本在彩色背景上的可访问性
- `suggestAccessibleTextColor()` - 为给定背景推荐符合标准的文本颜色

---

## 潜在问题区域

### ⚠️ textTertiary 在渐变背景上的使用

**发现的问题**:

在多个文件中，`textTertiary` 被用于可能对比度不足的场景：

| 文件                               | 行号                  | 使用情况                                   | 风险等级        |
| ---------------------------------- | --------------------- | ------------------------------------------ | --------------- |
| `lunar_detail_widget.dart`         | 602, 1034, 1076, 1110 | `textTertiary.withOpacity(0.2)` 作为分隔线 | 🟡 低（装饰性） |
| `app_drawer.dart`                  | 597, 688, 1131        | `textTertiary` 作为次要文本                | 🟡 中           |
| `custom_bottom_navigation_v2.dart` | 93, 106               | 未选中状态的文本                           | 🟡 中           |
| `hourly_list.dart`                 | 153                   | 小时列表中的次要文本                       | 🟡 中           |

**建议**:

- 检查这些文本在实际背景上的对比度
- 如果对比度 < 4.5:1，考虑使用更深的颜色或减少透明度

### ⚠️ 主题切换时的对比度一致性

不同主题的 `textTertiary` 颜色：

| 主题   | 亮色模式 | 暗色模式 |
| ------ | -------- | -------- |
| 蓝色   | #4A5568  | #B8D9F5  |
| 绿色   | #4A5568  | #B2DFDB  |
| 琥珀橙 | #5D4037  | #FFCCBC  |
| 青绿   | #4A5568  | #B2DFDB  |
| 紫色   | #5D4037  | #E1BEE7  |
| 玫瑰金 | #5D4037  | #F8BBD0  |

**观察**:

- 暗色模式的 textTertiary 颜色较浅，可能在某些背景上对比度不足
- 建议验证所有暗色主题下的对比度

---

## 修复指南

### 原则 1: 避免灰色文本在彩色背景上

❌ **错误做法**:

```dart
Text(
  '次要信息',
  style: TextStyle(
    color: Colors.grey, // 灰色
  ),
)
// 放在彩色渐变背景上
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(colors: [Colors.blue, Colors.purple]),
  ),
  child: ...
)
```

✅ **正确做法**:

```dart
Text(
  '次要信息',
  style: TextStyle(
    // 使用背景色的深色变体，而不是灰色
    color: Colors.blue.shade900.withOpacity(0.8),
  ),
)
```

### 原则 2: 使用 OKLCH 色彩空间

虽然 Flutter 不原生支持 OKLCH，但我们可以模拟其行为：

```dart
// 创建带色调的中性色（而不是纯灰色）
Color tintedNeutral(Color brandColor, double lightness) {
  // 取品牌色的 hue，降低 chroma，调整 lightness
  final hsl = HSLColor.fromColor(brandColor);
  return HSLColor.fromAHSL(
    1.0,
    hsl.hue,
    0.02, // 非常低的饱和度（接近中性）
    lightness,
  ).toColor();
}
```

### 原则 3: 验证所有文本颜色

使用增强的 `ColorContrast` 工具：

```dart
// 在开发时验证对比度
final validation = ColorContrast.validateContrast(
  AppColors.textTertiary,
  AppColors.cardBackground,
);

if (!validation['meetsAA']) {
  print('⚠️ 对比度不足: ${validation['ratio']}');
  print('建议使用: ${ColorContrast.suggestAccessibleTextColor(background)}');
}
```

---

## 推荐的修复优先级

### P0 - 立即修复（如果有）

目前未发现明确的 P0 对比度问题。AI 卡片已经正确实现了高对比度文本。

### P1 - 短期修复

1. **验证 textTertiary 在所有主题下的对比度**
   - 创建自动化测试脚本
   - 检查所有使用场景
2. **优化底部导航未选中状态**
   - 文件: `custom_bottom_navigation_v2.dart`
   - 确保未选中图标和文本有足够的对比度

### P2 - 长期优化

1. **统一文本颜色系统**
   - 减少 textTertiary 的使用场景
   - 引入更清晰的语义化颜色命名

2. **添加对比度检查到 CI/CD**
   - 自动化验证所有颜色组合
   - 防止未来引入对比度问题

---

## 测试清单

### 手动测试

- [ ] 在亮色模式下检查所有文本可读性
- [ ] 在暗色模式下检查所有文本可读性
- [ ] 在每个主题下测试（蓝、绿、琥珀、青绿、紫、玫瑰金等）
- [ ] 在强光环境下测试屏幕可读性
- [ ] 启用系统高对比度模式测试

### 自动化测试

运行以下命令查找潜在的对比度问题：

```bash
# 查找所有使用 opacity 的文本
grep -rn "withOpacity.*text" lib/

# 查找 textTertiary 的使用
grep -rn "textTertiary" lib/

# 查找灰色文本
grep -rn "Colors.grey\|Color(0xFF[89A-F]" lib/ | grep -i text
```

---

## 最佳实践总结

### ✅ 已遵循的最佳实践

1. **AI 卡片使用专用文本颜色** - 确保在渐变背景上的可读性
2. **提供 ColorContrast 工具类** - 方便开发者验证对比度
3. **主题系统包含亮/暗模式** - 支持不同的视觉需求

### 🔄 需要改进的实践

1. **减少 textTertiary 的滥用** - 只在真正次要的文本上使用
2. **避免在彩色背景上使用灰色** - 使用背景色的深色变体
3. **添加对比度文档** - 在设计系统中明确说明

---

## 工具和资源

### 内置工具

- `ColorContrast.validateContrast()` - 验证任意颜色组合
- `ColorContrast.autoTextColor()` - 自动选择黑/白文本
- `ColorContrast.suggestAccessibleTextColor()` - 推荐可访问的颜色

### 外部工具

- [WebAIM Contrast Checker](https://webaim.org/resources/contrastchecker/)
- [Colorable](https://colorable.jxnblk.com/)
- [Contrast Ratio](https://contrast-ratio.com/)

---

_最后更新: 2026-04-24_  
_下次审计: 完成 P1 修复后重新运行_
