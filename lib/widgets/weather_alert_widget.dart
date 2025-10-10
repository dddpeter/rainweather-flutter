import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/weather_alert_model.dart';
import '../models/commute_advice_model.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../providers/theme_provider.dart';

/// 天气提醒组件
class WeatherAlertWidget extends StatefulWidget {
  final List<WeatherAlertModel> alerts;
  final VoidCallback? onTap;
  final bool showAll;
  final int maxItems;

  const WeatherAlertWidget({
    super.key,
    required this.alerts,
    this.onTap,
    this.showAll = false,
    this.maxItems = 3,
  });

  @override
  State<WeatherAlertWidget> createState() => _WeatherAlertWidgetState();
}

class _WeatherAlertWidgetState extends State<WeatherAlertWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.alerts.isEmpty) {
      return const SizedBox.shrink();
    }

    // 收起时只显示第一条，展开时显示所有
    final displayAlerts = _isExpanded || widget.showAll
        ? widget.alerts
        : [widget.alerts.first];

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
              // 标题行（可点击展开/收起）
              InkWell(
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_rounded,
                        color: _getAlertIconColor(widget.alerts.first.level),
                        size: AppConstants.sectionTitleIconSize,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '天气提醒',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: AppConstants.sectionTitleFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 提醒数量标签（始终显示）
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.textSecondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${widget.alerts.length}条',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (widget.onTap != null) ...[
                        InkWell(
                          onTap: widget.onTap,
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: Text(
                              '更多',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 提醒列表
              ...displayAlerts.asMap().entries.map((entry) {
                final index = entry.key;
                final alert = entry.value;
                final isCollapsed =
                    !_isExpanded && !widget.showAll && index == 0;
                return _buildAlertItem(alert, showFullContent: !isCollapsed);
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建单个提醒项（符合 MD3 规范，可点击跳转）
  Widget _buildAlertItem(
    WeatherAlertModel alert, {
    bool showFullContent = true,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final backgroundOpacity = themeProvider.isLightTheme ? 0.15 : 0.25;

    return InkWell(
      onTap: widget.onTap, // 点击小卡片跳转到天气提醒详情页
      borderRadius: BorderRadius.circular(4),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _getAlertBackgroundColor(
            alert.level,
          ).withOpacity(backgroundOpacity),
          borderRadius: BorderRadius.circular(4),
        ),
        child: showFullContent
            ? _buildFullAlertContent(alert)
            : _buildCollapsedAlertContent(alert),
      ),
    );
  }

  /// 构建收起状态的提醒内容（只显示标题）
  Widget _buildCollapsedAlertContent(WeatherAlertModel alert) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final iconBackgroundOpacity = themeProvider.isLightTheme ? 0.2 : 0.3;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _getAlertBackgroundColor(
              alert.level,
            ).withOpacity(iconBackgroundOpacity),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(alert.levelIcon, style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 4),
              Text(
                _getAlertLevelText(alert.level),
                style: TextStyle(
                  color: _getAlertBackgroundColor(alert.level),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            alert.title,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (alert.isRequired)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(iconBackgroundOpacity),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '必提醒',
              style: TextStyle(
                color: Colors.red,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  /// 构建展开状态的提醒内容（显示完整信息）
  Widget _buildFullAlertContent(WeatherAlertModel alert) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final iconBackgroundOpacity = themeProvider.isLightTheme ? 0.2 : 0.3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 提醒标题行
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _getAlertBackgroundColor(
                  alert.level,
                ).withOpacity(iconBackgroundOpacity),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(alert.levelIcon, style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 4),
                  Text(
                    _getAlertLevelText(alert.level),
                    style: TextStyle(
                      color: _getAlertBackgroundColor(alert.level),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                alert.title,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (alert.isRequired)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(iconBackgroundOpacity),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '必提醒',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // 提醒内容
        Text(
          alert.content,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            height: 1.4,
          ),
        ),

        // 提醒原因和阈值
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                '原因: ${alert.reason}',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
            ),
            Text(
              '阈值: ${alert.threshold}',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
          ],
        ),

        // 场景提醒标识
        if (alert.isScenarioBased && alert.scenario != null) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(iconBackgroundOpacity),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.access_time, color: Colors.orange, size: 12),
                const SizedBox(width: 4),
                Text(
                  '场景提醒: ${alert.scenario}',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// 获取提醒级别对应的颜色
  Color _getAlertIconColor(WeatherAlertLevel level) {
    switch (level) {
      case WeatherAlertLevel.red:
        return Colors.red;
      case WeatherAlertLevel.yellow:
        return Colors.orange;
      case WeatherAlertLevel.blue:
        return Colors.blue;
      case WeatherAlertLevel.info:
        return Colors.green;
    }
  }

  /// 获取提醒级别对应的背景颜色
  Color _getAlertBackgroundColor(WeatherAlertLevel level) {
    switch (level) {
      case WeatherAlertLevel.red:
        return Colors.red;
      case WeatherAlertLevel.yellow:
        return Colors.orange;
      case WeatherAlertLevel.blue:
        return Colors.blue;
      case WeatherAlertLevel.info:
        return Colors.green;
    }
  }

  /// 获取提醒级别文本
  String _getAlertLevelText(WeatherAlertLevel level) {
    switch (level) {
      case WeatherAlertLevel.red:
        return '红色预警';
      case WeatherAlertLevel.yellow:
        return '黄色预警';
      case WeatherAlertLevel.blue:
        return '蓝色预警';
      case WeatherAlertLevel.info:
        return '信息提醒';
    }
  }
}

/// 简化的天气提醒组件（用于顶部显示）
class CompactWeatherAlertWidget extends StatelessWidget {
  final List<WeatherAlertModel> alerts;
  final int commuteCount; // 通勤提醒数量
  final VoidCallback? onTap;

  const CompactWeatherAlertWidget({
    super.key,
    required this.alerts,
    this.commuteCount = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 计算总提醒数
    final totalCount = alerts.length + commuteCount;

    if (totalCount == 0) {
      return const SizedBox(width: 40);
    }

    // 获取最高优先级的天气提醒（如果有）
    final topAlert = alerts.isNotEmpty
        ? alerts
              .where((alert) => alert.shouldShow)
              .fold<WeatherAlertModel?>(
                null,
                (prev, alert) => prev == null || alert.priority < prev.priority
                    ? alert
                    : prev,
              )
        : null;

    // 如果没有天气提醒，但有通勤提醒，使用默认颜色
    final iconColor = topAlert != null
        ? _getAlertColor(topAlert.level)
        : const Color(0xFFFFB300); // 琥珀色（通勤提醒默认颜色）

    return IconButton(
      onPressed: onTap,
      icon: Stack(
        children: [
          Icon(
            Icons.warning_rounded,
            color: iconColor,
            size: AppColors.titleBarIconSize,
          ),
          if (totalCount > 1)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(8),
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  '$totalCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getAlertColor(WeatherAlertLevel level) {
    switch (level) {
      case WeatherAlertLevel.red:
        return Colors.red;
      case WeatherAlertLevel.yellow:
        return Colors.orange;
      case WeatherAlertLevel.blue:
        return Colors.blue;
      case WeatherAlertLevel.info:
        return Colors.green;
    }
  }
}

/// 综合提醒详情页面（天气提醒 + 通勤提醒）
class WeatherAlertDetailScreen extends StatelessWidget {
  final List<WeatherAlertModel> alerts;
  final List<CommuteAdviceModel> commuteAdvices;

  const WeatherAlertDetailScreen({
    super.key,
    required this.alerts,
    this.commuteAdvices = const [],
  });

  @override
  Widget build(BuildContext context) {
    final totalCount = alerts.length + commuteAdvices.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('综合提醒 ($totalCount条)'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.primaryGradient),
        child: totalCount == 0
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 64,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '暂无提醒',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // 天气提醒区域
                  if (alerts.isNotEmpty) ...[
                    _buildSectionHeader('天气提醒', alerts.length, Icons.cloud),
                    const SizedBox(height: 8),
                    ...alerts.map(
                      (alert) => Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: _buildAlertCard(alert),
                      ),
                    ),
                  ],

                  // 通勤提醒区域
                  if (commuteAdvices.isNotEmpty) ...[
                    if (alerts.isNotEmpty) const SizedBox(height: 8),
                    _buildSectionHeader(
                      '通勤提醒',
                      commuteAdvices.length,
                      Icons.commute,
                    ),
                    const SizedBox(height: 8),
                    ...commuteAdvices.map(
                      (advice) => Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: _buildCommuteCard(advice),
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  /// 构建区域标题
  Widget _buildSectionHeader(String title, int count, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.accentBlue, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.accentBlue.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: AppColors.accentBlue,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(WeatherAlertModel alert) {
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
            // 标题行
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _getAlertColor(alert.level).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        alert.levelIcon,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _getAlertLevelText(alert.level),
                        style: TextStyle(
                          color: _getAlertColor(alert.level),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    alert.title,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (alert.isRequired)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '必须提醒',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // 内容
            Text(
              alert.content,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),

            // 详细信息
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('天气词条', alert.weatherTerm),
                  _buildInfoRow('提醒原因', alert.reason),
                  _buildInfoRow('建议阈值', alert.threshold),
                  _buildInfoRow('城市', alert.cityName),
                  if (alert.isScenarioBased && alert.scenario != null)
                    _buildInfoRow('触发场景', alert.scenario!),
                  _buildInfoRow('创建时间', _formatDateTime(alert.createdAt)),
                  if (alert.expiresAt != null)
                    _buildInfoRow('过期时间', _formatDateTime(alert.expiresAt!)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: AppColors.textPrimary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Color _getAlertColor(WeatherAlertLevel level) {
    switch (level) {
      case WeatherAlertLevel.red:
        return Colors.red;
      case WeatherAlertLevel.yellow:
        return Colors.orange;
      case WeatherAlertLevel.blue:
        return Colors.blue;
      case WeatherAlertLevel.info:
        return Colors.green;
    }
  }

  String _getAlertLevelText(WeatherAlertLevel level) {
    switch (level) {
      case WeatherAlertLevel.red:
        return '红色预警';
      case WeatherAlertLevel.yellow:
        return '黄色预警';
      case WeatherAlertLevel.blue:
        return '蓝色预警';
      case WeatherAlertLevel.info:
        return '信息提醒';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// 构建通勤提醒卡片
  Widget _buildCommuteCard(CommuteAdviceModel advice) {
    final levelColor = advice.getLevelColor();
    final levelName = advice.getLevelName();

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
            // 标题行
            Row(
              children: [
                // 图标
                Text(advice.icon, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                // 级别标签
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: levelColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    levelName,
                    style: TextStyle(
                      color: levelColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          advice.title,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // AI标签（仅AI生成的建议显示）
                      if (advice.adviceType == 'ai_smart') ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFB300).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                color: const Color(0xFFFFB300),
                                size: 10,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                'AI',
                                style: TextStyle(
                                  color: const Color(0xFFFFB300),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 内容
            Text(
              advice.content,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),

            // 详细信息
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('时段', advice.timeSlot.name),
                  _buildInfoRow('创建时间', _formatDateTime(advice.timestamp)),
                  _buildInfoRow('建议类型', advice.adviceType),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
