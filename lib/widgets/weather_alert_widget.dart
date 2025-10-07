import 'package:flutter/material.dart';
import '../models/weather_alert_model.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';

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
              // 标题行
              InkWell(
                onTap: widget.alerts.length > 1
                    ? () {
                        setState(() {
                          _isExpanded = !_isExpanded;
                        });
                      }
                    : null,
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
                      if (widget.alerts.length > 1)
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
                      if (widget.alerts.length > 1)
                        Icon(
                          _isExpanded ? Icons.expand_less : Icons.expand_more,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                      if (widget.onTap != null) ...[
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: widget.onTap,
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.arrow_forward_ios,
                              color: AppColors.textSecondary,
                              size: 16,
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

  /// 构建单个提醒项
  Widget _buildAlertItem(
    WeatherAlertModel alert, {
    bool showFullContent = true,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getAlertBackgroundColor(alert.level).withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getAlertBackgroundColor(alert.level).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: showFullContent
          ? _buildFullAlertContent(alert)
          : _buildCollapsedAlertContent(alert),
    );
  }

  /// 构建收起状态的提醒内容（只显示标题）
  Widget _buildCollapsedAlertContent(WeatherAlertModel alert) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getAlertBackgroundColor(alert.level).withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
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
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withOpacity(0.3), width: 1),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 提醒标题行
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getAlertBackgroundColor(alert.level).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
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
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.3),
                    width: 1,
                  ),
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
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.orange.withOpacity(0.3),
                width: 1,
              ),
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
  final VoidCallback? onTap;

  const CompactWeatherAlertWidget({
    super.key,
    required this.alerts,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) {
      return const SizedBox(width: 40);
    }

    // 获取最高优先级的提醒
    final topAlert = alerts
        .where((alert) => alert.shouldShow)
        .fold<WeatherAlertModel?>(
          null,
          (prev, alert) =>
              prev == null || alert.priority < prev.priority ? alert : prev,
        );

    if (topAlert == null) {
      return const SizedBox(width: 40);
    }

    return IconButton(
      onPressed: onTap,
      icon: Stack(
        children: [
          Icon(
            Icons.warning_rounded,
            color: _getAlertColor(topAlert.level),
            size: AppColors.titleBarIconSize,
          ),
          if (alerts.length > 1)
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
                  '${alerts.length}',
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

/// 天气提醒详情页面
class WeatherAlertDetailScreen extends StatelessWidget {
  final List<WeatherAlertModel> alerts;

  const WeatherAlertDetailScreen({super.key, required this.alerts});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('天气提醒 (${alerts.length}条)'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.primaryGradient),
        child: alerts.isEmpty
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
                      '暂无天气提醒',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: alerts.length,
                itemBuilder: (context, index) {
                  final alert = alerts[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: _buildAlertCard(alert),
                  );
                },
              ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getAlertColor(alert.level).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _getAlertColor(alert.level).withOpacity(0.3),
                      width: 1,
                    ),
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
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.red.withOpacity(0.3),
                        width: 1,
                      ),
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
}
