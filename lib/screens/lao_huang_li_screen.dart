import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../constants/app_colors.dart';
import '../services/lunar_service.dart';
import '../models/lunar_model.dart';
import 'lunar_calendar_screen.dart';

/// 老黄历详情页面
class LaoHuangLiScreen extends StatefulWidget {
  final DateTime? selectedDate;

  const LaoHuangLiScreen({super.key, this.selectedDate});

  @override
  State<LaoHuangLiScreen> createState() => _LaoHuangLiScreenState();
}

class _LaoHuangLiScreenState extends State<LaoHuangLiScreen> {
  late DateTime _selectedDate;
  LunarInfo? _lunarInfo;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate ?? DateTime.now();
    _loadLunarInfo();
  }

  void _loadLunarInfo() {
    try {
      final lunarService = LunarService.getInstance();
      setState(() {
        _lunarInfo = lunarService.getLunarInfo(_selectedDate);
      });
    } catch (e) {
      print('❌ 加载农历信息失败: $e');
    }
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
              '黄历详情',
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
              IconButton(
                icon: Icon(Icons.calendar_today, color: AppColors.textPrimary),
                onPressed: _selectDate,
              ),
            ],
          ),
          body: _lunarInfo == null
              ? Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryBlue,
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 日期选择卡片
                      _buildDateCard(),
                      const SizedBox(height: 12),

                      // 农历日期卡片
                      _buildLunarDateCard(),
                      const SizedBox(height: 12),

                      // 节气节日
                      if (_lunarInfo!.hasSpecialDay()) ...[
                        _buildSpecialDayCard(),
                        const SizedBox(height: 12),
                      ],

                      // 宜忌卡片
                      _buildYiJiCard(),
                      const SizedBox(height: 12),

                      // 吉神方位卡片
                      _buildDirectionCard(),
                      const SizedBox(height: 12),

                      // 详细信息卡片
                      _buildDetailCard(),
                      const SizedBox(height: 12),

                      // 彭祖百忌
                      _buildPengZuCard(),
                    ],
                  ),
                ),
        );
      },
    );
  }

  /// 日期选择卡片 - 占满一行，日期和星期在一行
  Widget _buildDateCard() {
    return Card(
      elevation: AppColors.cardElevation,
      shadowColor: AppColors.cardShadowColor,
      color: AppColors.materialCardColor,
      surfaceTintColor: Colors.transparent,
      shape: AppColors.cardShape,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '${_selectedDate.year}年${_selectedDate.month}月${_selectedDate.day}日',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22, // 从28缩小到22
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              _getWeekDay(_selectedDate),
              style: TextStyle(
                color: AppColors.warning, // 改为橙色以区分
                fontSize: 22, // 从20改为22，与日期一样大
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 农历日期卡片 - 今日提醒样式
  Widget _buildLunarDateCard() {
    return Card(
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
            Row(
              children: [
                Icon(
                  Icons.calendar_month_rounded,
                  color: AppColors.warning,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Text(
                  '农历信息',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 第一行：农历、干支（统一使用primaryBlue）- IntrinsicHeight确保高度一致
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _buildTipStyleItem(
                      Icons.calendar_today,
                      '农历',
                      _lunarInfo!.getFullLunarDate(),
                      AppColors.primaryBlue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTipStyleItem(
                      Icons.style,
                      '干支',
                      '${_lunarInfo!.yearGanZhi} ${_lunarInfo!.monthGanZhi} ${_lunarInfo!.dayGanZhi}',
                      AppColors.primaryBlue,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // 第二行：星座、星宿（统一使用warning，居中对齐）- IntrinsicHeight确保高度一致
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _buildCenterAlignItem(
                      '星座',
                      _lunarInfo!.constellation,
                      AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStarItem(
                      '星宿',
                      _lunarInfo!.starName,
                      _lunarInfo!.starLuck,
                      AppColors.warning,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 节气节日卡片
  Widget _buildSpecialDayCard() {
    final hasSpecialDay = _lunarInfo!.hasSpecialDay();
    if (!hasSpecialDay) return const SizedBox.shrink();

    final lunarService = LunarService.getInstance();
    final hasSolarTerm =
        _lunarInfo!.solarTerm != null && _lunarInfo!.solarTerm!.isNotEmpty;
    final hasFestivals = _lunarInfo!.festivals.isNotEmpty;

    return Card(
      elevation: AppColors.cardElevation,
      shadowColor: AppColors.cardShadowColor,
      color: AppColors.materialCardColor,
      surfaceTintColor: Colors.transparent,
      shape: AppColors.cardShape,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.error.withOpacity(0.08),
              AppColors.warning.withOpacity(0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 节气（如果有）
            if (hasSolarTerm) ...[
              _buildSpecialDayItem(
                '节气',
                _lunarInfo!.solarTerm!,
                lunarService.getSolarTermEmoji(_lunarInfo!.solarTerm!),
                lunarService.getSolarTermDescription(_lunarInfo!.solarTerm!),
                AppColors.warning,
              ),
              if (hasFestivals) const SizedBox(height: 16),
            ],

            // 节日（如果有）- 可能有多个
            if (hasFestivals) ...[
              ..._lunarInfo!.festivals.asMap().entries.map((entry) {
                final festival = entry.value;
                final isLast = entry.key == _lunarInfo!.festivals.length - 1;
                return Column(
                  children: [
                    _buildSpecialDayItem(
                      '节日',
                      festival,
                      lunarService.getFestivalEmoji(festival),
                      lunarService.getFestivalDescription(festival),
                      AppColors.error,
                    ),
                    if (!isLast) const SizedBox(height: 16),
                  ],
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  /// 构建单个节气/节日项
  Widget _buildSpecialDayItem(
    String type,
    String name,
    String emoji,
    String description,
    Color color,
  ) {
    return Column(
      children: [
        Row(
          children: [
            // 大图标
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 40)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      type,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    name,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20, // 从24缩小到20
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (description.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.borderColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.primaryBlue,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    description,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12, // 从14进一步缩小到12
                      fontWeight: FontWeight.w500,
                      height: 1.3, // 调整行高
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// 宜忌卡片
  Widget _buildYiJiCard() {
    return Card(
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
            Row(
              children: [
                Icon(
                  Icons.event_available_rounded,
                  color: AppColors.accentGreen,
                  size: 24, // 从20增大到24
                ),
                const SizedBox(width: 10),
                Text(
                  '宜忌',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18, // 从16增大到18
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_lunarInfo!.isHuangDaoDay)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, color: AppColors.warning, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '黄道吉日',
                          style: TextStyle(
                            color: AppColors.warning,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // 宜和忌并排显示 - IntrinsicHeight确保高度一致
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 宜
                  Expanded(
                    child: _buildTipStyleItem(
                      Icons.check_circle_outline,
                      '宜',
                      _lunarInfo!.goodThings.isEmpty
                          ? '诸事不宜'
                          : _lunarInfo!.goodThings.join('、'),
                      AppColors.accentGreen,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 忌
                  Expanded(
                    child: _buildTipStyleItem(
                      Icons.cancel_outlined,
                      '忌',
                      _lunarInfo!.badThings.isEmpty
                          ? '百无禁忌'
                          : _lunarInfo!.badThings.join('、'),
                      AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 吉神方位卡片
  Widget _buildDirectionCard() {
    return Card(
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
            Row(
              children: [
                Icon(
                  Icons.explore_rounded,
                  color: AppColors.primaryBlue,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Text(
                  '吉神方位',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 说明文字
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.borderColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.primaryBlue,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '传统认为朝这些方位祈福会更加吉利',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildDirectionItem(
                    '喜神',
                    '求喜事',
                    LunarService.getInstance().convertDirectionToCommon(
                      _lunarInfo!.xiShenDirection,
                    ),
                    AppColors.error,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildDirectionItem(
                    '福神',
                    '求福气',
                    LunarService.getInstance().convertDirectionToCommon(
                      _lunarInfo!.fuShenDirection,
                    ),
                    AppColors.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildDirectionItem(
                    '财神',
                    '求财运',
                    LunarService.getInstance().convertDirectionToCommon(
                      _lunarInfo!.caiShenDirection,
                    ),
                    AppColors.accentGreen,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildDirectionItem(
                    '冲煞',
                    '需避讳',
                    _lunarInfo!.chongSha,
                    AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 详细信息卡片 - 今日提醒样式
  Widget _buildDetailCard() {
    return Card(
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
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.primaryBlue,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Text(
                  '详细信息',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 建除和冲煞在一行（统一使用primaryBlue和warning）- IntrinsicHeight确保高度一致
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _buildCenterAlignItem(
                      '建除',
                      _lunarInfo!.jianChu,
                      AppColors.primaryBlue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildCenterAlignItem(
                      '冲煞',
                      _lunarInfo!.chongSha,
                      AppColors.warning,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 彭祖百忌卡片
  Widget _buildPengZuCard() {
    return Card(
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
            Row(
              children: [
                Icon(
                  Icons.report_problem_outlined,
                  color: AppColors.warning,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Text(
                  '彭祖百忌',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.08),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _lunarInfo!.pengZuBaiji,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建方位项 - 老年人友好版本
  Widget _buildDirectionItem(
    String label,
    String description,
    String direction,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
          const SizedBox(height: 8),
          Text(
            direction,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  /// 信息卡片项 - 参考吉神方位样式，无图标（内容左对齐）
  Widget _buildTipStyleItem(
    IconData icon, // 保留参数以兼容，但不使用
    String label,
    String value,
    Color color,
  ) {
    final themeProvider = context.read<ThemeProvider>();
    final backgroundOpacity = themeProvider.isLightTheme ? 0.08 : 0.25;

    return Container(
      constraints: const BoxConstraints(
        minHeight: 85, // 固定最小高度
      ),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(backgroundOpacity),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start, // 标题固定在顶部
        crossAxisAlignment: CrossAxisAlignment.stretch, // 填充整个宽度
        children: [
          // 标签 - 居中
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          // 内容 - 左对齐
          Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
            textAlign: TextAlign.left, // 左对齐
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// 星宿信息卡片 - 带颜色的吉凶显示
  Widget _buildStarItem(
    String label,
    String starName,
    String starLuck,
    Color color,
  ) {
    final themeProvider = context.read<ThemeProvider>();
    final backgroundOpacity = themeProvider.isLightTheme ? 0.08 : 0.25;

    // 根据吉凶选择颜色
    final luckColor = starLuck == '吉' ? AppColors.accentGreen : AppColors.error;

    return Container(
      constraints: const BoxConstraints(
        minHeight: 85, // 固定最小高度
      ),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(backgroundOpacity),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start, // 标题固定在顶部
        children: [
          // 标签 - 居中
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          // 内容 - 星宿名+吉凶（带颜色）
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                TextSpan(
                  text: starName,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
                TextSpan(
                  text: '($starLuck)',
                  style: TextStyle(
                    color: luckColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 信息卡片项 - 内容居中对齐版本（用于详细信息卡片）
  Widget _buildCenterAlignItem(String label, String value, Color color) {
    final themeProvider = context.read<ThemeProvider>();
    final backgroundOpacity = themeProvider.isLightTheme ? 0.08 : 0.25;

    return Container(
      constraints: const BoxConstraints(
        minHeight: 85, // 固定最小高度
      ),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(backgroundOpacity),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start, // 标题固定在顶部
        children: [
          // 标签 - 居中
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          // 内容 - 居中
          Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
            textAlign: TextAlign.center, // 居中对齐
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// 选择日期 - 使用农历日历页面
  Future<void> _selectDate() async {
    final DateTime? picked = await Navigator.push<DateTime>(
      context,
      MaterialPageRoute(
        builder: (context) => LunarCalendarScreen(
          initialDate: _selectedDate,
          isSelectMode: true, // 选择模式
        ),
      ),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadLunarInfo();
    }
  }

  /// 获取星期
  String _getWeekDay(DateTime date) {
    const weekDays = ['星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'];
    return weekDays[date.weekday - 1];
  }
}
