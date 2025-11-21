import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../constants/app_colors.dart';
import '../services/lunar_service.dart';
import '../services/ai_service.dart';
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
  final AIService _aiService = AIService();

  String? _pengZuInterpretation;
  bool _isLoadingPengZuInterpretation = false;
  DateTime? _cachedPengZuDate;
  String? _cachedPengZuText;

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

      // 加载彭祖百忌解读
      _loadPengZuInterpretation();
    } catch (e) {
      print('❌ 加载农历信息失败: $e');
    }
  }

  /// 加载彭祖百忌解读（带10天缓存）
  Future<void> _loadPengZuInterpretation() async {
    if (_lunarInfo == null) return;

    final pengZuText = _lunarInfo!.pengZuBaiji;
    final now = DateTime.now();

    // 检查缓存：如果彭祖文字相同且缓存在10天内，直接返回
    if (_pengZuInterpretation != null &&
        _cachedPengZuText == pengZuText &&
        _cachedPengZuDate != null) {
      final daysDiff = now.difference(_cachedPengZuDate!).inDays;
      if (daysDiff < 10) {
        return;
      }
    }

    setState(() {
      _isLoadingPengZuInterpretation = true;
    });

    try {
      // 检查AI服务是否有这个方法，如果没有就创建一个简单的解读
      final interpretation = await _aiService.generateSmartAdvice(
        '请解释这个传统历法概念："${pengZuText}"，用通俗易懂的语言说明其含义和背后的道理，控制在100字以内。',
      );

      if (mounted && interpretation != null) {
        setState(() {
          _pengZuInterpretation = interpretation;
          _cachedPengZuText = pengZuText;
          _cachedPengZuDate = now;
          _isLoadingPengZuInterpretation = false;
        });
      } else if (mounted) {
        setState(() {
          _isLoadingPengZuInterpretation = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingPengZuInterpretation = false;
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
                '黄历详情',
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
                IconButton(
                  icon: Icon(
                    Icons.calendar_today,
                    color: themeProvider.isLightTheme
                        ? AppColors.primaryBlue
                        : AppColors.accentBlue,
                  ),
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
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 顶部：日期和农历信息合并
                        _buildCompactHeader(),
                        const SizedBox(height: 12),

                        // 节气节日（如果有）
                        if (_lunarInfo!.hasSpecialDay()) ...[
                          _buildSpecialDayCard(),
                          const SizedBox(height: 12),
                        ],

                        // 宜忌和吉神方位合并卡片
                        _buildMergedCard(),
                        const SizedBox(height: 12),

                        // 彭祖百忌
                        _buildPengZuCard(),
                      ],
                    ),
                  ),
          ),
        );
      },
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
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '彭祖百忌',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 彭祖百忌原文
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

            const SizedBox(height: 12),

            // AI解读
            if (_isLoadingPengZuInterpretation)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: AppColors.primaryBlue.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: AppColors.primaryBlue,
                        strokeWidth: 2,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '正在解读...',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              )
            else if (_pengZuInterpretation != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: AppColors.primaryBlue.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          color: AppColors.primaryBlue,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'AI解读',
                          style: TextStyle(
                            color: AppColors.primaryBlue,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _pengZuInterpretation!,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        height: 1.5,
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

  /// 紧凑顶部：日期+农历信息合并
  Widget _buildCompactHeader() {
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
            // 公历日期和星期
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '${_selectedDate.year}年${_selectedDate.month}月${_selectedDate.day}日',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _getWeekDay(_selectedDate),
                  style: TextStyle(
                    color: AppColors.warning,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 农历信息：列表布局
            _buildDetailRow(
              Icons.calendar_month,
              '农历',
              _lunarInfo!.getFullLunarDate(),
              '',
              AppColors.primaryBlue,
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              Icons.history,
              '干支',
              '${_lunarInfo!.yearGanZhi} ${_lunarInfo!.monthGanZhi} ${_lunarInfo!.dayGanZhi}',
              '',
              AppColors.primaryBlue,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildDetailSmallCard(
                    '星座',
                    _lunarInfo!.constellation,
                    AppColors.warning,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStarSmallCard(
                    '星宿',
                    _lunarInfo!.starName,
                    _lunarInfo!.starLuck,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 合并卡片：宜忌 + 吉神方位
  Widget _buildMergedCard() {
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
            // 宜忌部分
            Row(
              children: [
                Icon(
                  Icons.event_available_rounded,
                  color: AppColors.accentGreen,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '宜忌',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
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

            // 宜忌内容 - 列表行布局
            _buildDetailRow(
              Icons.check_circle_outline,
              '宜',
              _lunarInfo!.goodThings.isEmpty
                  ? '诸事不宜'
                  : _lunarInfo!.goodThings.join('、'),
              '',
              AppColors.accentGreen,
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              Icons.cancel_outlined,
              '忌',
              _lunarInfo!.badThings.isEmpty
                  ? '百无禁忌'
                  : _lunarInfo!.badThings.join('、'),
              '',
              AppColors.error,
            ),

            const SizedBox(height: 20),

            // 分隔线
            Container(
              height: 1,
              color: AppColors.textTertiary.withOpacity(0.2),
            ),

            const SizedBox(height: 20),

            // 吉神方位部分
            Row(
              children: [
                Icon(Icons.explore, color: AppColors.primaryBlue, size: 20),
                const SizedBox(width: 8),
                Text(
                  '吉神方位',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 吉神方位 - 竖向卡片布局
            Row(
              children: [
                Expanded(
                  child: _buildDirectionCard(
                    '财神',
                    LunarService.getInstance().convertDirectionToCommon(
                      _lunarInfo!.caiShenDirection,
                    ),
                    AppColors.accentGreen,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildDirectionCard(
                    '喜神',
                    LunarService.getInstance().convertDirectionToCommon(
                      _lunarInfo!.xiShenDirection,
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
                  child: _buildDirectionCard(
                    '福神',
                    LunarService.getInstance().convertDirectionToCommon(
                      _lunarInfo!.fuShenDirection,
                    ),
                    AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildDirectionCard(
                    '冲煞',
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

  /// 构建方位竖向卡片
  Widget _buildDirectionCard(String label, String direction, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            direction,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 构建详情小卡片（星座等）
  Widget _buildDetailSmallCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建星宿小卡片（星宿 + 吉凶）
  Widget _buildStarSmallCard(String label, String starName, String starLuck) {
    // 判断吉凶颜色
    final isGood = starLuck == '吉';
    final luckColor = isGood ? AppColors.accentGreen : AppColors.warning;
    final luckTextColor = isGood
        ? const Color(0xFFFFD700) // 吉字黄色
        : Colors.red; // 凶字红色

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: luckColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              color: luckColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$starName(',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: starLuck,
                    style: TextStyle(
                      color: luckTextColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: ')',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建详情行（参考海报组件的列表样式）
  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value,
    String description,
    Color iconColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          // 彩色图标背景
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: iconColor.withOpacity(0.6), width: 1),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        value,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      description,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 获取星期
  String _getWeekDay(DateTime date) {
    const weekDays = ['星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'];
    return weekDays[date.weekday - 1];
  }
}
