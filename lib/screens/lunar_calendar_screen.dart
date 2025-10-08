import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../constants/app_colors.dart';
import '../services/lunar_service.dart';
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

        return Scaffold(
          backgroundColor: AppColors.backgroundPrimary,
          appBar: AppBar(
            backgroundColor: AppColors.backgroundPrimary,
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
                                Icons.star,
                                color: AppColors.warning,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '带星号的为黄道吉日',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
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
              ],
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
        left: 12,
        right: 12,
        top: 12,
        bottom: 0,
      ), // 底部无padding
      child: GridView.builder(
        shrinkWrap: true, // 根据内容自动调整高度
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          childAspectRatio: 0.65, // 单元格更高
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
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
      child: Container(
        decoration: BoxDecoration(
          color: isToday
              ? AppColors.primaryBlue.withOpacity(0.15)
              : Colors.transparent, // 节假日也不要背景
          borderRadius: BorderRadius.circular(8),
          border: isToday
              ? Border.all(color: AppColors.primaryBlue, width: 2)
              : null, // 节假日也不要边框
        ),
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 公历日期 - 顶部
            Text(
              '${date.day}',
              style: TextStyle(
                color: isCurrentMonth
                    ? (isToday
                          ? AppColors.primaryBlue
                          : isWeekend
                          ? AppColors.error
                          : AppColors.textPrimary)
                    : AppColors.textTertiary,
                fontSize: 16, // 从17缩小到16
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 3),

            // 农历/节气/节日 - 中间
            if (isCurrentMonth) ...[
              // 处理节气和节日共存的情况
              if (lunarInfo.solarTerm != null &&
                  lunarInfo.solarTerm!.isNotEmpty)
                Text(
                  lunarInfo.solarTerm!,
                  style: TextStyle(
                    color: AppColors.error,
                    fontSize: 9, // 从10缩小到9
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                )
              else if (lunarInfo.festivals.isNotEmpty)
                Text(
                  lunarInfo.festivals.length > 1
                      ? '${lunarInfo.festivals.first}等'
                      : lunarInfo.festivals.first,
                  style: TextStyle(
                    color: AppColors.error,
                    fontSize: 9, // 从10缩小到9
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                )
              else
                Text(
                  _getLunarDayDisplay(lunarInfo),
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 9, // 从10缩小到9
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
            ] else
              // 非当前月占位
              const SizedBox(height: 13),

            // 黄道吉日标识 - 底部
            if (isCurrentMonth && lunarInfo.isHuangDaoDay) ...[
              const SizedBox(height: 2),
              Icon(Icons.star, color: AppColors.warning, size: 10),
            ] else
              const SizedBox(height: 12), // 占位保持对齐
          ],
        ),
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
  String _getLunarDayDisplay(lunarInfo) {
    if (lunarInfo.lunarDay == '初一') {
      // lunarMonth 可能是 "正"、"腊" 等，需要加上"月"字
      final month = lunarInfo.lunarMonth;
      return month.endsWith('月') ? month : '$month月';
    }
    return lunarInfo.lunarDay;
  }
}
