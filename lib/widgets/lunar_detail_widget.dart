import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/lunar_model.dart';
import '../providers/theme_provider.dart';
import '../services/lunar_service.dart';
import '../services/ai_service.dart';

/// 农历详情组件
class LunarDetailWidget extends StatelessWidget {
  final LunarInfo lunarInfo;
  final DateTime selectedDate;

  const LunarDetailWidget({
    super.key,
    required this.lunarInfo,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(8), // 减小外边距，使内容更紧凑
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 顶部：日期和农历信息合并
              _buildCompactHeader(themeProvider),
              const SizedBox(height: 8), // 减小间距

              // 节气节日（如果有）
              if (lunarInfo.hasSpecialDay()) ...[
                _buildSpecialDayCard(themeProvider),
                const SizedBox(height: 8), // 减小间距
              ],

              // 宜忌和吉神方位合并卡片
              _buildMergedCard(themeProvider),
              const SizedBox(height: 8), // 减小间距

              // 彭祖百忌
              _buildPengZuCard(themeProvider),
            ],
          ),
        );
      },
    );
  }

  /// 节气节日卡片
  Widget _buildSpecialDayCard(ThemeProvider themeProvider) {
    final hasSpecialDay = lunarInfo.hasSpecialDay();
    if (!hasSpecialDay) return const SizedBox.shrink();

    final lunarService = LunarService.getInstance();
    final hasSolarTerm =
        lunarInfo.solarTerm != null && lunarInfo.solarTerm!.isNotEmpty;
    final hasFestivals = lunarInfo.festivals.isNotEmpty;

    return Card(
      elevation: AppColors.cardElevation,
      shadowColor: AppColors.cardShadowColor,
      color: AppColors.materialCardColor,
      surfaceTintColor: Colors.transparent,
      shape: AppColors.cardShape,
      child: Container(
        padding: const EdgeInsets.all(12), // 减小内边距
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.error.withOpacity(0.06), // 降低透明度，更柔和
              AppColors.warning.withOpacity(0.06), // 降低透明度，更柔和
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
                lunarInfo.solarTerm!,
                lunarService.getSolarTermEmoji(lunarInfo.solarTerm!),
                lunarService.getSolarTermDescription(lunarInfo.solarTerm!),
                AppColors.warning, // 使用主题颜色
              ),
              if (hasFestivals) const SizedBox(height: 12), // 减小间距
            ],

            // 节日（如果有）- 可能有多个
            if (hasFestivals) ...[
              ...lunarInfo.festivals.asMap().entries.map((entry) {
                final festival = entry.value;
                final isLast = entry.key == lunarInfo.festivals.length - 1;
                return Column(
                  children: [
                    _buildSpecialDayItem(
                      '节日',
                      festival,
                      lunarService.getFestivalEmoji(festival),
                      lunarService.getFestivalDescription(festival),
                      AppColors.error, // 使用主题颜色
                    ),
                    if (!isLast) const SizedBox(height: 12), // 减小间距
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
              width: 56, // 减小尺寸
              height: 56, // 减小尺寸
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10), // 减小圆角
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 32)), // 减小字体
              ),
            ),
            const SizedBox(width: 12), // 减小间距
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6, // 减小内边距
                      vertical: 3, // 减小内边距
                    ),
                    decoration: BoxDecoration(
                      color: color, // 使用传入的主题颜色
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      type,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10, // 减小字体
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4), // 减小间距
                  Text(
                    name,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18, // 进一步减小字体
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
          const SizedBox(height: 8), // 减小间距
          Container(
            padding: const EdgeInsets.all(10), // 减小内边距
            decoration: BoxDecoration(
              color: AppColors.borderColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(6), // 减小圆角
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.primaryBlue, // 使用主题颜色
                  size: 16, // 减小图标
                ),
                const SizedBox(width: 6), // 减小间距
                Expanded(
                  child: Text(
                    description,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 11, // 进一步减小字体
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
  Widget _buildPengZuCard(ThemeProvider themeProvider) {
    return PengZuCard(lunarInfo: lunarInfo);
  }

  /// 紧凑顶部：日期+农历信息合并
  Widget _buildCompactHeader(ThemeProvider themeProvider) {
    return CompactHeader(
      selectedDate: selectedDate,
      lunarInfo: lunarInfo,
    );
  }

  /// 合并卡片：宜忌 + 吉神方位
  Widget _buildMergedCard(ThemeProvider themeProvider) {
    return MergedCard(lunarInfo: lunarInfo);
  }

}

/// 紧凑顶部组件
class CompactHeader extends StatelessWidget {
  final DateTime selectedDate;
  final LunarInfo lunarInfo;

  const CompactHeader({
    super.key,
    required this.selectedDate,
    required this.lunarInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Card(
          elevation: AppColors.cardElevation,
          shadowColor: AppColors.cardShadowColor,
          color: AppColors.materialCardColor,
          surfaceTintColor: Colors.transparent,
          shape: AppColors.cardShape,
          child: Padding(
            padding: const EdgeInsets.all(12), // 减小内边距
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
                      '${selectedDate.month}月${selectedDate.day}日', // 简化显示，去掉年份
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16, // 减小字体
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 8), // 减小间距
                    Text(
                      _getWeekDay(selectedDate),
                      style: TextStyle(
                        color: AppColors.warning, // 使用主题颜色
                        fontSize: 16, // 减小字体
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12), // 减小间距

                // 农历信息：列表布局
                _buildDetailRow(
                  Icons.calendar_month,
                  '农历',
                  lunarInfo.getFullLunarDate(),
                  '',
                  AppColors.primaryBlue, // 使用主题颜色
                ),
                const SizedBox(height: 6), // 减小间距
                _buildDetailRow(
                  Icons.history,
                  '干支',
                  '${lunarInfo.yearGanZhi} ${lunarInfo.monthGanZhi} ${lunarInfo.dayGanZhi}',
                  '',
                  AppColors.primaryBlue, // 使用主题颜色
                ),
                const SizedBox(height: 6), // 减小间距
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailSmallCard(
                        '星座',
                        lunarInfo.constellation,
                        AppColors.warning, // 使用主题颜色
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStarSmallCard(
                        '星宿',
                        lunarInfo.starName,
                        lunarInfo.starLuck,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
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
      padding: const EdgeInsets.symmetric(vertical: 4), // 减小垂直间距
      child: Row(
        children: [
          // 彩色图标背景
          Container(
            padding: const EdgeInsets.all(6), // 减小内边距
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8), // 减小圆角
              border: Border.all(color: iconColor.withOpacity(0.6), width: 1),
            ),
            child: Icon(icon, color: iconColor, size: 18), // 减小图标
          ),
          const SizedBox(width: 10), // 减小间距
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6, // 减小间距
                  runSpacing: 3, // 减小间距
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13, // 减小字体
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      value,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13, // 减小字体
                        fontWeight: FontWeight.bold,
                      ),
                      // 允许折行显示完整文字
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
                        fontSize: 10, // 减小字体
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

  /// 构建方位竖向卡片
  Widget _buildDetailSmallCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12), // 减小内边距
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10), // 减小圆角
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color, // 使用传入的主题颜色
              fontSize: 10, // 减小字体
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6), // 减小间距
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14, // 减小字体
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
    final luckColor = isGood ? AppColors.accentGreen : AppColors.warning; // 使用主题颜色
    final luckTextColor = isGood
        ? const Color(0xFFFFD700) // 吉字黄色
        : Colors.red; // 凶字红色

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12), // 减小内边距
      decoration: BoxDecoration(
        color: luckColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10), // 减小圆角
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              color: luckColor, // 使用主题颜色
              fontSize: 10, // 减小字体
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6), // 减小间距
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$starName(',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14, // 减小字体
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: starLuck,
                    style: TextStyle(
                      color: luckTextColor,
                      fontSize: 14, // 减小字体
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: ')',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14, // 减小字体
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

  /// 获取星期
  String _getWeekDay(DateTime date) {
    const weekDays = ['星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'];
    return weekDays[date.weekday - 1];
  }
}

/// 合并卡片组件
class MergedCard extends StatelessWidget {
  final LunarInfo lunarInfo;

  const MergedCard({
    super.key,
    required this.lunarInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: AppColors.cardElevation,
      shadowColor: AppColors.cardShadowColor,
      color: AppColors.materialCardColor,
      surfaceTintColor: Colors.transparent,
      shape: AppColors.cardShape,
      child: Padding(
        padding: const EdgeInsets.all(12), // 减小内边距
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 宜忌部分
            Row(
              children: [
                Icon(
                  Icons.event_available_rounded,
                  color: AppColors.accentGreen, // 使用主题颜色
                  size: 18, // 减小图标
                ),
                const SizedBox(width: 6), // 减小间距
                Text(
                  '宜忌',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15, // 减小字体
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (lunarInfo.isHuangDaoDay)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6, // 减小内边距
                      vertical: 3, // 减小内边距
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, color: AppColors.warning, size: 12), // 减小图标
                        const SizedBox(width: 3), // 减小间距
                        Text(
                          '黄道吉日',
                          style: TextStyle(
                            color: AppColors.warning, // 使用主题颜色
                            fontSize: 11, // 减小字体
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8), // 减小间距

            // 宜忌内容 - 两列布局：上面是标签，下面是内容
            YiJiTwoColumnLayout(
              goodThings: lunarInfo.goodThings.isEmpty
                  ? '诸事不宜'
                  : lunarInfo.goodThings.join('、'),
              badThings: lunarInfo.badThings.isEmpty
                  ? '百无禁忌'
                  : lunarInfo.badThings.join('、'),
            ),

            const SizedBox(height: 16), // 减小间距

            // 分隔线
            Container(
              height: 1,
              color: AppColors.textTertiary.withOpacity(0.2),
            ),

            const SizedBox(height: 16), // 减小间距

            // 吉神方位部分
            Row(
              children: [
                Icon(Icons.explore, color: AppColors.primaryBlue, size: 18), // 减小图标，使用主题颜色
                const SizedBox(width: 6), // 减小间距
                Text(
                  '吉神方位',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15, // 减小字体
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8), // 减小间距

            // 吉神方位 - 竖向卡片布局
            Row(
              children: [
                Expanded(
                  child: DirectionCard(
                    label: '财神',
                    direction: LunarService.getInstance().convertDirectionToCommon(
                      lunarInfo.caiShenDirection,
                    ),
                    color: AppColors.accentGreen, // 使用主题颜色
                  ),
                ),
                const SizedBox(width: 6), // 减小间距
                Expanded(
                  child: DirectionCard(
                    label: '喜神',
                    direction: LunarService.getInstance().convertDirectionToCommon(
                      lunarInfo.xiShenDirection,
                    ),
                    color: AppColors.warning, // 使用主题颜色
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6), // 减小间距
            Row(
              children: [
                Expanded(
                  child: DirectionCard(
                    label: '福神',
                    direction: LunarService.getInstance().convertDirectionToCommon(
                      lunarInfo.fuShenDirection,
                    ),
                    color: AppColors.primaryBlue, // 使用主题颜色
                  ),
                ),
                const SizedBox(width: 6), // 减小间距
                Expanded(
                  child: DirectionCard(
                    label: '冲煞',
                    direction: lunarInfo.chongSha,
                    color: AppColors.textSecondary, // 使用主题颜色
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 彭祖百忌卡片组件
class PengZuCard extends StatefulWidget {
  final LunarInfo lunarInfo;

  const PengZuCard({
    super.key,
    required this.lunarInfo,
  });

  @override
  State<PengZuCard> createState() => _PengZuCardState();
}

class _PengZuCardState extends State<PengZuCard> {
  String? _pengZuInterpretation;
  bool _isLoadingPengZuInterpretation = false;
  DateTime? _cachedPengZuDate;
  String? _cachedPengZuText;
  final AIService _aiService = AIService();

  @override
  void initState() {
    super.initState();
    _loadPengZuInterpretation();
  }

  /// 加载彭祖百忌解读（带10天缓存）
  Future<void> _loadPengZuInterpretation() async {
    final pengZuText = widget.lunarInfo.pengZuBaiji;
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
    return Builder(
      builder: (context) {
        final themeProvider = context.read<ThemeProvider>();
        
        // AI渐变色：使用常量
        final aiGradient = themeProvider.isLightTheme
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.aiGradientLightDark.withOpacity(AppColors.aiGradientOpacity),
                  AppColors.aiGradientLightMid.withOpacity(AppColors.aiGradientOpacity),
                  AppColors.aiGradientLightLight.withOpacity(AppColors.aiGradientOpacity),
                ],
                stops: const [0.0, 0.5, 1.0],
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.aiGradientDarkDark.withOpacity(AppColors.aiGradientOpacity),
                  AppColors.aiGradientDarkMid.withOpacity(AppColors.aiGradientOpacity),
                  AppColors.aiGradientDarkLight.withOpacity(AppColors.aiGradientOpacity),
                ],
                stops: const [0.0, 0.5, 1.0],
              );
        
        // 文字颜色：使用常量，确保高对比度
        final textColor = themeProvider.isLightTheme
            ? AppColors.aiTextColorLight
            : AppColors.aiTextColorDark;
        
        // 图标颜色：与文字颜色一致
        final iconColor = textColor;

        return Card(
          elevation: AppColors.cardElevation,
          shadowColor: AppColors.cardShadowColor,
          color: AppColors.materialCardColor,
          surfaceTintColor: Colors.transparent,
          shape: AppColors.cardShape,
          child: Padding(
            padding: const EdgeInsets.all(12), // 减小内边距
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.report_problem_outlined,
                      color: AppColors.warning, // 使用主题颜色
                      size: 18, // 减小图标
                    ),
                    const SizedBox(width: 6), // 减小间距
                    Text(
                      '彭祖百忌',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15, // 减小字体
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8), // 减小间距
                // 彭祖百忌原文
                Container(
                  padding: const EdgeInsets.all(10), // 减小内边距
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    widget.lunarInfo.pengZuBaiji,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13, // 减小字体
                      height: 1.4, // 减小行高
                    ),
                  ),
                ),

                const SizedBox(height: 8), // 减小间距

                // AI解读 - 使用AI卡片样式
                Container(
                  margin: const EdgeInsets.only(top: 8), // 减小外边距
                  decoration: BoxDecoration(
                    gradient: aiGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10), // 减小内边距
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              color: iconColor, // 使用高对比度图标颜色
                              size: 14, // 减小图标
                            ),
                            const SizedBox(width: 5), // 减小间距
                            Text(
                              'AI解读',
                              style: TextStyle(
                                color: textColor, // 使用高对比度文字颜色
                                fontSize: 12, // 减小字体
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            // AI标签：使用白色背景+深色文字，确保高对比度
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5, // 减小内边距
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(
                                  themeProvider.isLightTheme
                                      ? AppColors.labelWhiteBgOpacityLight
                                      : AppColors.labelWhiteBgOpacityDark
                                ),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: textColor.withOpacity(AppColors.labelBorderOpacity),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.auto_awesome,
                                    color: textColor, // 使用高对比度颜色
                                    size: 9, // 减小图标
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    'AI',
                                    style: TextStyle(
                                      color: textColor, // 使用高对比度颜色
                                      fontSize: 9, // 减小字体
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6), // 减小间距
                        if (_isLoadingPengZuInterpretation)
                          Row(
                            children: [
                              SizedBox(
                                width: 14, // 减小尺寸
                                height: 14,
                                child: CircularProgressIndicator(
                                  color: textColor, // 使用高对比度颜色
                                  strokeWidth: 2,
                                ),
                              ),
                              const SizedBox(width: 10), // 减小间距
                              Text(
                                '正在解读...',
                                style: TextStyle(
                                  color: textColor, // 使用高对比度文字颜色
                                  fontSize: 12, // 减小字体
                                ),
                              ),
                            ],
                          )
                        else if (_pengZuInterpretation != null)
                          Text(
                            _pengZuInterpretation!,
                            style: TextStyle(
                              color: textColor, // 使用高对比度文字颜色
                              fontSize: 12, // 减小字体
                              height: 1.4, // 减小行高
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 方位竖向卡片组件
class DirectionCard extends StatelessWidget {
  final String label;
  final String direction;
  final Color color;

  const DirectionCard({
    super.key,
    required this.label,
    required this.direction,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10), // 减小内边距
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10), // 减小圆角
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color, // 使用传入的主题颜色
              fontSize: 11, // 减小字体
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6), // 减小间距
          Text(
            direction,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14, // 减小字体
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// 宜忌两列布局组件
class YiJiTwoColumnLayout extends StatelessWidget {
  final String goodThings;
  final String badThings;

  const YiJiTwoColumnLayout({
    super.key,
    required this.goodThings,
    required this.badThings,
  });

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        final themeProvider = context.read<ThemeProvider>();
        final isLightTheme = themeProvider.isLightTheme;
        
        return Column(
          children: [
            // 第一行：标签（两列，居中对齐，高度相等）
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 宜标签
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6), // 减小内边距
                      decoration: BoxDecoration(
                        color: AppColors.accentGreen.withOpacity(isLightTheme ? 0.1 : 0.15),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(4),
                        ),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '😊',
                              style: TextStyle(fontSize: 14), // 减小字体
                            ),
                            const SizedBox(width: 3), // 减小间距
                            Text(
                              '宜',
                              style: TextStyle(
                                color: AppColors.accentGreen, // 使用主题颜色
                                fontSize: 13, // 减小字体
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // 中间分隔线
                  Container(
                    width: 1,
                    color: AppColors.textTertiary.withOpacity(0.2),
                  ),
                  // 忌标签
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6), // 减小内边距
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(isLightTheme ? 0.1 : 0.15),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(8),
                        ),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '😟',
                              style: TextStyle(fontSize: 14), // 减小字体
                            ),
                            const SizedBox(width: 3), // 减小间距
                            Text(
                              '忌',
                              style: TextStyle(
                                color: AppColors.error, // 使用主题颜色
                                fontSize: 13, // 减小字体
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // 标签和内容之间的分隔线
            Container(
              height: 1,
              color: AppColors.textTertiary.withOpacity(0.2),
            ),
            // 第二行：内容（两列，左对齐，高度相等）
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 宜内容
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10), // 减小内边距
                      decoration: BoxDecoration(
                        color: AppColors.accentGreen.withOpacity(isLightTheme ? 0.05 : 0.1),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(8),
                          bottomRight: Radius.circular(4),
                        ),
                      ),
                      child: Text(
                        goodThings,
                        textAlign: TextAlign.left, // 左对齐
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13, // 减小字体
                          fontWeight: FontWeight.bold,
                          height: 1.4, // 减小行高
                        ),
                        // 允许折行显示完整文字
                      ),
                    ),
                  ),
                  // 中间分隔线
                  Container(
                    width: 1,
                    color: AppColors.textTertiary.withOpacity(0.2),
                  ),
                  // 忌内容
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10), // 减小内边距
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(isLightTheme ? 0.05 : 0.1),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(4),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                      child: Text(
                        badThings,
                        textAlign: TextAlign.left, // 左对齐
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13, // 减小字体
                          fontWeight: FontWeight.bold,
                          height: 1.4, // 减小行高
                        ),
                        // 允许折行显示完整文字
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}