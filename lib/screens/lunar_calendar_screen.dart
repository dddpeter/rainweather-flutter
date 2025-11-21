import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../services/lunar_service.dart';
// import '../services/ai_service.dart'; // 暂未使用，注释掉
import '../models/lunar_model.dart';
import 'lao_huang_li_screen.dart';

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
  // final AIService _aiService = AIService(); // 暂未使用，注释掉

  @override
  void initState() {
    super.initState();
    _selectedMonth = widget.initialDate ?? DateTime.now();
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
              elevation: 4,
              backgroundColor: Colors.transparent,
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  // 半透明背景 - 基于主题色，已包含透明度
                  color: AppColors.appBarBackground,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(0.5),
                child: Container(
                  height: 0.5,
                  color: themeProvider.getColor('border').withOpacity(0.2),
                ),
              ),
              foregroundColor: themeProvider.isLightTheme
                  ? AppColors.primaryBlue
                  : AppColors.accentBlue,
              title: Text(
                '黄历节日',
                style: TextStyle(
                  color: themeProvider.isLightTheme
                      ? AppColors.primaryBlue
                      : AppColors.accentBlue,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: themeProvider.isLightTheme
                      ? AppColors.primaryBlue
                      : AppColors.accentBlue,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
              actions: [
                // 今天按钮 - 简洁版本
                IconButton(
                  icon: Text(
                    '今',
                    style: TextStyle(
                      color: themeProvider.isLightTheme
                          ? AppColors.primaryBlue
                          : AppColors.accentBlue,
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

                  // 黄道吉日表格
                  _buildHuangDaoTable(),
                ],
              ),
            ),
          ),
        );
      },
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
                  // 非当前月也显示农历日期
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _getLunarDayDisplay(lunarInfo),
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
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

  /// 构建黄道吉日表格
  Widget _buildHuangDaoTable() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    // 获取近2个月的黄道吉日数据
    final huangDaoDays = _getHuangDaoDaysForNext2Months();

    if (huangDaoDays.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.screenHorizontalPadding,
      ),
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
              // 标题
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.accentBlue.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.calendar_today,
                          color: AppColors.accentBlue,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '近2个月黄道吉日',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: AppConstants.sectionTitleFontSize,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '适合现代人的重要活动日期',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 表格容器
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.borderColor.withOpacity(0.2),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    // 表头
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primaryBlue.withOpacity(0.15),
                            AppColors.primaryBlue.withOpacity(0.08),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                border: Border(
                                  right: BorderSide(
                                    color: AppColors.borderColor.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: Text(
                                '日期',
                                style: TextStyle(
                                  color: AppColors.primaryBlue,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 5,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
                              child: Text(
                                '适合的活动',
                                style: TextStyle(
                                  color: AppColors.primaryBlue,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 数据行
                    ...huangDaoDays.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      final isLast = index == huangDaoDays.length - 1;

                      return Container(
                        decoration: BoxDecoration(
                          color: index % 2 == 0
                              ? Colors.transparent
                              : AppColors.primaryBlue.withOpacity(0.15),
                          borderRadius: isLast
                              ? const BorderRadius.only(
                                  bottomLeft: Radius.circular(8),
                                  bottomRight: Radius.circular(8),
                                )
                              : null,
                          border: Border(
                            bottom: BorderSide(
                              color: themeProvider.isLightTheme
                                  ? AppColors.primaryBlue.withOpacity(0.2)
                                  : AppColors.accentBlue.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 日期列
                            Expanded(
                              flex: 2,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  border: Border(
                                    right: BorderSide(
                                      color: AppColors.borderColor
                                          .withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['date'] as String,
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    // 添加农历日期显示
                                    if (item['lunarDate'] != null)
                                      Text(
                                        item['lunarDate'] as String,
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            // 活动列
                            Expanded(
                              flex: 5,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 14,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: _buildActivityRows(
                                    item['activities'] as String,
                                    item['activitiesList'] as List<String>? ?? [],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建活动行列表（标签+解释，一行一个）
  List<Widget> _buildActivityRows(String activitiesStr, List<String> activitiesList) {
    final List<Widget> rows = [];
    
    // 检查是否包含"等X项"
    final hasMore = activitiesStr.contains('等') && activitiesStr.contains('项');
    
    List<String> activities;
    int? moreCount;
    
    if (hasMore) {
      // 提取"等"之前的内容和"等X项"
      final match = RegExp(r'(.+?)等(\d+)项').firstMatch(activitiesStr);
      if (match != null) {
        activities = match.group(1)!.split('、');
        moreCount = int.tryParse(match.group(2)!);
      } else {
        activities = activitiesList.isNotEmpty ? activitiesList : activitiesStr.split('、');
      }
    } else {
      activities = activitiesList.isNotEmpty ? activitiesList : activitiesStr.split('、');
    }
    
    // 为每个活动创建一行（标签+解释）
    for (var i = 0; i < activities.length; i++) {
      final activity = activities[i];
      final explanation = _getSingleActivityExplanation(activity);
      final isLast = i == activities.length - 1;
      
      rows.add(
        Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildActivityTag(activity),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    explanation,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 1.6,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // 如果有更多项，添加提示
    if (hasMore && moreCount != null) {
      rows.add(
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '等$moreCount项',
            style: TextStyle(
              color: AppColors.textTertiary,
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }
    
    return rows;
  }

  /// 获取单个活动的现代解释
  String _getSingleActivityExplanation(String activity) {
    // 活动名称到现代解释的映射
    final explanationMap = {
      '结婚': '举办婚礼，步入婚姻殿堂',
      '嫁娶': '结婚嫁娶，喜结良缘',
      '订婚': '确定婚约，定下终身大事',
      '领证': '领取结婚证，正式登记',
      '开业': '新店开业，生意兴隆',
      '开张': '店铺开张，财源广进',
      '搬家': '乔迁新居，生活更美好',
      '入宅': '搬入新家，安居乐业',
      '乔迁': '搬迁新居，新环境新开始',
      '出行': '外出旅行，放松心情',
      '旅游': '出门旅游，开阔视野',
      '签约': '签署合同，达成协议',
      '合同': '签订合同，建立合作关系',
      '协议': '达成协议，明确权责',
      '装修': '房屋装修，改善居住环境',
      '动土': '开始施工，建设新项目',
      '开工': '项目开工，事业起步',
      '买车': '购买汽车，提升出行便利',
      '购车': '购置车辆，改善生活质量',
      '买房': '购买房产，投资置业',
      '购房': '购置房产，安家落户',
      '投资': '进行投资，财富增值',
      '理财': '理财规划，合理配置资产',
      '考试': '参加考试，发挥最佳水平',
      '面试': '求职面试，展现能力',
      '求职': '寻找工作，开启新职业',
      '入职': '正式入职，开始新工作',
      '手术': '进行手术，恢复健康',
      '就医': '看病就医，治疗疾病',
      '理发': '修剪头发，焕然一新',
      '美容': '美容护理，提升形象',
      '提车': '提取新车，开启新旅程',
      '上牌': '办理车牌，车辆上牌',
      '纳财': '收取钱财，财运亨通',
      '交易': '进行交易，买卖成交',
      '开市': '市场开市，生意开张',
      '立券': '签订契约，确立关系',
      '安床': '安置床铺，改善睡眠',
      '安葬': '安葬逝者，入土为安',
      '祭祀': '祭拜祖先，表达敬意',
      '祈福': '祈求福运，心想事成',
      '求嗣': '求子求女，延续香火',
      '解除': '解除合约，了结事务',
      '拆卸': '拆除旧物，清理空间',
      '修造': '修建改造，改善环境',
      '栽种': '种植植物，绿化环境',
      '破土': '破土动工，开始建设',
      '安香': '安置香炉，供奉神明',
      '出火': '生火做饭，开火仪式',
      '移徙': '搬迁移居，改变住所',
      '挂匾': '悬挂牌匾，正式开业',
      '入殓': '入殓仪式，告别逝者',
      '除服': '脱去丧服，结束守孝',
      '成服': '穿上丧服，开始守孝',
      '启攒': '开启攒盒，开始储蓄',
      '安碓': '安置石臼，准备加工',
      '安门': '安装门户，完善设施',
      '伐木': '砍伐树木，获取材料',
      '上梁': '房屋上梁，建筑重要节点',
    };
    
    // 查找匹配的解释
    for (final entry in explanationMap.entries) {
      if (activity.contains(entry.key)) {
        return entry.value;
      }
    }
    
    // 如果没有找到匹配的，返回通用解释
    return '$activity，适合进行';
  }

  /// 构建单个活动标签
  Widget _buildActivityTag(String activity, {bool isMore = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: isMore
            ? AppColors.textSecondary.withOpacity(0.12)
            : AppColors.warning.withOpacity(0.18),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isMore
              ? AppColors.textSecondary.withOpacity(0.3)
              : AppColors.warning.withOpacity(0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isMore
                ? Colors.transparent
                : AppColors.warning.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        activity,
        style: TextStyle(
          color: isMore
              ? AppColors.textSecondary
              : AppColors.warning,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  /// 获取近2个月的黄道吉日数据
  List<Map<String, dynamic>> _getHuangDaoDaysForNext2Months() {
    final now = DateTime.now();
    final endDate = DateTime(now.year, now.month + 2, 0); // 2个月后的最后一天
    final List<Map<String, dynamic>> huangDaoDays = [];

    // 现代人活动关键词
    const modernActivities = [
      '结婚',
      '嫁娶',
      '订婚',
      '领证',
      '开业',
      '开张',
      '搬家',
      '入宅',
      '乔迁',
      '出行',
      '旅游',
      '签约',
      '合同',
      '协议',
      '装修',
      '动土',
      '开工',
      '买车',
      '购车',
      '买房',
      '购房',
      '投资',
      '理财',
      '考试',
      '面试',
      '求职',
      '入职',
      '手术',
      '就医',
      '理发',
      '美容',
      '提车',
      '上牌',
      '纳财',
      '交易',
      '开市',
      '立券',
      '安床',
      '安葬',
      '祭祀',
      '祈福',
      '求嗣',
      '解除',
      '拆卸',
      '修造',
      '栽种',
      '破土',
      '安香',
      '出火',
      '移徙',
      '挂匾',
      '入殓',
      '除服',
      '成服',
      '启攒',
      '安碓',
      '安门',
      '伐木',
      '上梁',
    ];

    // 遍历近2个月的所有日期
    for (var date = now;
        date.isBefore(endDate) || date.isAtSameMomentAs(endDate);
        date = date.add(const Duration(days: 1))) {
      final lunarInfo = _lunarService.getLunarInfo(date);

      // 只处理黄道吉日
      if (!lunarInfo.isHuangDaoDay) continue;

      // 筛选适合现代人的活动
      final modernGoodThings = lunarInfo.goodThings.where((activity) {
        return modernActivities.any((keyword) => activity.contains(keyword));
      }).toList();

      // 如果没有适合现代人的活动，跳过
      if (modernGoodThings.isEmpty) continue;

      // 格式化日期（包含星期几）
      final weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
      final weekday = weekdays[date.weekday - 1];
      final dateStr = '${date.month}/${date.day} $weekday';

      // 限制活动数量，最多显示5个
      final activitiesToShow = modernGoodThings.take(5).toList();
      final activitiesStr = activitiesToShow.join('、');
      
      // 获取农历日期显示（包含月份）
      final lunarMonth = lunarInfo.lunarMonth;
      final lunarDay = lunarInfo.lunarDay;
      final lunarDateStr = '$lunarMonth月$lunarDay';
      
      if (modernGoodThings.length > 5) {
        final activitiesStrWithMore = '$activitiesStr等${modernGoodThings.length}项';
        huangDaoDays.add({
          'date': dateStr,
          'lunarDate': lunarDateStr,
          'activities': activitiesStrWithMore,
          'activitiesList': activitiesToShow,
        });
      } else {
        huangDaoDays.add({
          'date': dateStr,
          'lunarDate': lunarDateStr,
          'activities': activitiesStr,
          'activitiesList': activitiesToShow,
        });
      }
    }

    return huangDaoDays;
  }
}
