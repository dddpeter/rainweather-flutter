import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../services/lunar_service.dart';
import '../services/ai_service.dart';
import '../models/lunar_model.dart';
import 'lao_huang_li_screen.dart';
import '../widgets/typewriter_text_widget.dart';

/// 农历日历页面
class LunarCalendarScreen extends StatefulWidget {
  final DateTime? initialDate;
  final bool isSelectMode; // 是否为选择模式

  const LunarCalendarScreen({
    super.key,
    this.initialDate,
    this.isSelectMode = false,
  });

  @override
  State<LunarCalendarScreen> createState() => _LunarCalendarScreenState();
}

class _LunarCalendarScreenState extends State<LunarCalendarScreen> {
  late DateTime _selectedMonth;
  final LunarService _lunarService = LunarService.getInstance();
  final AIService _aiService = AIService();

  String? _lunarInterpretation;
  bool _isLoadingInterpretation = false;
  DateTime? _cachedInterpretationDate; // 缓存的解读日期

  /// 去掉Markdown格式符号，保留纯文本
  String _cleanMarkdownText(String text) {
    return text
        .replaceAll('**', '') // 去掉粗体符号
        .replaceAll('*', '') // 去掉剩余的星号
        .replaceAll('###', '') // 去掉H3标题符号
        .replaceAll('##', '') // 去掉H2标题符号
        .replaceAll('#', ''); // 去掉H1标题符号
  }

  @override
  void initState() {
    super.initState();
    _selectedMonth = widget.initialDate ?? DateTime.now();
    _loadLunarInterpretation();
  }

  Future<void> _loadLunarInterpretation({bool forceRefresh = false}) async {
    if (_isLoadingInterpretation) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 检查缓存：如果是今天且已有缓存，且不强制刷新，则直接返回
    if (!forceRefresh &&
        _cachedInterpretationDate != null &&
        _lunarInterpretation != null &&
        _cachedInterpretationDate!.year == today.year &&
        _cachedInterpretationDate!.month == today.month &&
        _cachedInterpretationDate!.day == today.day) {
      return;
    }

    setState(() {
      _isLoadingInterpretation = true;
    });

    try {
      final lunarInfo = _lunarService.getLunarInfo(now);

      final prompt = _aiService.buildLunarYiJiPrompt(
        goodThings: lunarInfo.goodThings.isEmpty
            ? '诸事不宜'
            : lunarInfo.goodThings.join('、'),
        badThings: lunarInfo.badThings.isEmpty
            ? '百无禁忌'
            : lunarInfo.badThings.join('、'),
        lunarDate: lunarInfo.lunarDate,
        isHuangDaoDay: lunarInfo.isHuangDaoDay,
        solarTerm: lunarInfo.solarTerm ?? '无节气',
      );

      final interpretation = await _aiService.generateSmartAdvice(prompt);

      if (mounted) {
        setState(() {
          _lunarInterpretation = interpretation;
          _cachedInterpretationDate = today; // 保存缓存日期
          _isLoadingInterpretation = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingInterpretation = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        AppColors.setThemeProvider(themeProvider);

        return Container(
          decoration: BoxDecoration(
            gradient: AppColors.screenBackgroundGradient,
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              foregroundColor: AppColors.textPrimary,
              elevation: 0,
              title: Text(
                '黄历节日',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
                onPressed: () => Navigator.of(context).pop(),
              ),
              actions: [
                // 今天按钮 - 简洁版本
                IconButton(
                  icon: Text(
                    '今',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  tooltip: '今天',
                  onPressed: () {
                    setState(() {
                      _selectedMonth = DateTime.now();
                    });
                  },
                ),
              ],
            ),
            body: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 8),

                  // 日历主体（带背景和圆角）
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.materialCardColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.cardShadowColor,
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // 月份选择器
                          _buildMonthSelector(),

                          // 星期标题
                          _buildWeekdayHeader(),

                          // 日历网格
                          _buildCalendarGrid(),

                          // 底部说明 - 放在日历容器内
                          Container(
                            margin: const EdgeInsets.only(top: 8), // 从日历底部开始的间距
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                            ), // 从12减到10
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(12),
                                bottomRight: Radius.circular(12),
                              ),
                              border: Border(
                                top: BorderSide(
                                  color: AppColors.borderColor.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.circle,
                                  color: AppColors.warning,
                                  size: 8,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '橙色标记为黄道吉日',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // AI黄历解读卡片（放在日历下方）
                  _buildLunarInterpretationCard(themeProvider),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 构建AI黄历解读卡片
  Widget _buildLunarInterpretationCard(ThemeProvider themeProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: AppColors.cardElevation,
        shadowColor: AppColors.cardShadowColor,
        color: AppColors.materialCardColor,
        surfaceTintColor: Colors.transparent,
        shape: AppColors.cardShape,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题栏
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: AppColors.accentBlue,
                    size: AppConstants.sectionTitleIconSize,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '今日黄历解读',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: AppConstants.sectionTitleFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  // AI标签
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color:
                          (themeProvider.isLightTheme
                                  ? const Color(0xFF004CFF)
                                  : const Color(0xFFFFB300))
                              .withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          color: themeProvider.isLightTheme
                              ? const Color(0xFF004CFF)
                              : const Color(0xFFFFB300),
                          size: 10,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          'AI',
                          style: TextStyle(
                            color: themeProvider.isLightTheme
                                ? const Color(0xFF004CFF)
                                : const Color(0xFFFFB300),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // AI解读内容
              if (_isLoadingInterpretation)
                Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: AppColors.accentBlue),
                      const SizedBox(height: 12),
                      Text(
                        '正在生成黄历解读...',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              else if (_lunarInterpretation != null)
                TypewriterTextWidget(
                  text: _cleanMarkdownText(_lunarInterpretation!),
                  charDelay: const Duration(milliseconds: 30),
                  lineDelay: const Duration(milliseconds: 200),
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 月份选择器
  Widget _buildMonthSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        border: Border(
          bottom: BorderSide(
            color: AppColors.borderColor.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 上月按钮 - 更大的点击区域
          Container(
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: Icon(
                Icons.chevron_left,
                color: AppColors.primaryBlue,
                size: 32, // 更大的图标
              ),
              iconSize: 32,
              padding: const EdgeInsets.all(12),
              onPressed: () {
                setState(() {
                  _selectedMonth = DateTime(
                    _selectedMonth.year,
                    _selectedMonth.month - 1,
                  );
                });
              },
            ),
          ),
          // 月份显示 - 更大的字体
          InkWell(
            onTap: _selectMonth,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Text(
                '${_selectedMonth.year}年 ${_selectedMonth.month}月',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22, // 从18增大到22
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          // 下月按钮 - 更大的点击区域
          Container(
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: Icon(
                Icons.chevron_right,
                color: AppColors.primaryBlue,
                size: 32, // 更大的图标
              ),
              iconSize: 32,
              padding: const EdgeInsets.all(12),
              onPressed: () {
                setState(() {
                  _selectedMonth = DateTime(
                    _selectedMonth.year,
                    _selectedMonth.month + 1,
                  );
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 星期标题
  Widget _buildWeekdayHeader() {
    const weekDays = ['一', '二', '三', '四', '五', '六', '日'];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.borderColor.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: weekDays.map((day) {
          final isWeekend = day == '六' || day == '日';
          return Expanded(
            child: Center(
              child: Text(
                day,
                style: TextStyle(
                  color: isWeekend ? AppColors.error : AppColors.textSecondary,
                  fontSize: 16, // 从14增大到16
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 日历网格
  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month,
      1,
    );
    final lastDayOfMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + 1,
      0,
    );
    final daysInMonth = lastDayOfMonth.day;

    // 获取第一天是星期几（1=周一, 7=周日）
    final firstWeekday = firstDayOfMonth.weekday;

    // 计算需要显示的前一个月的天数
    final previousMonthDays = firstWeekday - 1;
    final previousMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month,
      0,
    );

    return Padding(
      padding: const EdgeInsets.only(
        left: 4,
        right: 4,
        top: 4,
        bottom: 0,
      ), // 底部无padding，进一步减少padding
      child: GridView.builder(
        shrinkWrap: true, // 根据内容自动调整高度
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          childAspectRatio: 0.65, // 恢复原来的高单元格设计
          crossAxisSpacing: 6,
          mainAxisSpacing: 2, // 进一步减少行间距到2
        ),
        itemCount: previousMonthDays + daysInMonth,
        itemBuilder: (context, index) {
          if (index < previousMonthDays) {
            // 上个月的日期（灰色显示）
            final day = previousMonth.day - previousMonthDays + index + 1;
            final date = DateTime(previousMonth.year, previousMonth.month, day);
            return _buildDayCell(date, isCurrentMonth: false);
          } else {
            // 本月的日期
            final day = index - previousMonthDays + 1;
            final date = DateTime(
              _selectedMonth.year,
              _selectedMonth.month,
              day,
            );
            return _buildDayCell(date, isCurrentMonth: true);
          }
        },
      ),
    );
  }

  /// 构建日期单元格
  Widget _buildDayCell(DateTime date, {required bool isCurrentMonth}) {
    final lunarInfo = _lunarService.getLunarInfo(date);
    final isToday = _isToday(date);
    final weekday = date.weekday;
    final isWeekend = weekday == 6 || weekday == 7;

    return InkWell(
      onTap: () {
        if (!isCurrentMonth) {
          setState(() {
            _selectedMonth = DateTime(date.year, date.month);
          });
        }

        // 如果是选择模式，返回选中的日期
        if (widget.isSelectMode) {
          Navigator.pop(context, date);
          return;
        }

        // 跳转到详细老黄历页面
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LaoHuangLiScreen(selectedDate: date),
          ),
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Builder(
        builder: (context) {
          return Container(
            decoration: BoxDecoration(
              color: isToday
                  ? AppColors.primaryBlue.withOpacity(0.15)
                  : Colors.transparent, // 节假日也不要背景
              borderRadius: BorderRadius.circular(8),
              border: isToday
                  ? Border.all(color: AppColors.primaryBlue, width: 2)
                  : null, // 去掉格子线
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 公历日期 - 顶部
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${date.day}',
                    style: TextStyle(
                      color: isCurrentMonth
                          ? (isToday
                                ? AppColors.primaryBlue
                                : isWeekend
                                ? AppColors.error
                                : AppColors.textPrimary)
                          : AppColors.textTertiary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 2),

                // 农历/节气/节日 - 中间
                if (isCurrentMonth) ...[
                  // 黄道吉日：带边框和颜色的背景
                  if (lunarInfo.isHuangDaoDay) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.warning, width: 1),
                      ),
                      child: Builder(
                        builder: (context) {
                          String text;
                          if (lunarInfo.solarTerm != null &&
                              lunarInfo.solarTerm!.isNotEmpty) {
                            text = lunarInfo.solarTerm!;
                          } else if (lunarInfo.festivals.isNotEmpty) {
                            text = lunarInfo.festivals.length > 1
                                ? '${lunarInfo.festivals.first}等'
                                : lunarInfo.festivals.first;
                          } else {
                            text = _getLunarDayDisplay(lunarInfo);
                          }

                          return FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              text,
                              style: TextStyle(
                                color: AppColors.warning,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          );
                        },
                      ),
                    ),
                  ]
                  // 非黄道吉日：普通显示
                  else if (lunarInfo.solarTerm != null &&
                      lunarInfo.solarTerm!.isNotEmpty)
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        lunarInfo.solarTerm!,
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    )
                  else if (lunarInfo.festivals.isNotEmpty)
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        lunarInfo.festivals.length > 1
                            ? '${lunarInfo.festivals.first}等'
                            : lunarInfo.festivals.first,
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _getLunarDayDisplay(lunarInfo),
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                ] else
                  // 非当前月占位
                  const SizedBox(height: 13),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 选择月份
  Future<void> _selectMonth() async {
    final initialDate = _selectedMonth;

    await showDialog(
      context: context,
      builder: (context) {
        int selectedYear = initialDate.year;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.backgroundSecondary,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              title: Text(
                '选择月份',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 年份选择
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.chevron_left,
                          color: AppColors.textPrimary,
                        ),
                        onPressed: () {
                          setDialogState(() {
                            selectedYear--;
                          });
                        },
                      ),
                      Text(
                        '$selectedYear年',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.chevron_right,
                          color: AppColors.textPrimary,
                        ),
                        onPressed: () {
                          setDialogState(() {
                            selectedYear++;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // 月份网格
                  GridView.builder(
                    shrinkWrap: true,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                    itemCount: 12,
                    itemBuilder: (context, index) {
                      final month = index + 1;
                      final isSelected =
                          selectedYear == _selectedMonth.year &&
                          month == _selectedMonth.month;

                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedMonth = DateTime(selectedYear, month);
                          });
                          Navigator.pop(context);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryBlue.withOpacity(0.15)
                                : AppColors.borderColor.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primaryBlue
                                  : AppColors.borderColor.withOpacity(0.2),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '$month月',
                              style: TextStyle(
                                color: isSelected
                                    ? AppColors.primaryBlue
                                    : AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    '取消',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// 判断是否是今天
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// 获取农历日期显示（初一显示月份）
  String _getLunarDayDisplay(LunarInfo lunarInfo) {
    if (lunarInfo.lunarDay == '初一') {
      // lunarMonth 可能是 "正"、"腊" 等，需要加上"月"字
      final month = lunarInfo.lunarMonth;
      return month.endsWith('月') ? month : '$month月';
    }
    return lunarInfo.lunarDay;
  }
}
