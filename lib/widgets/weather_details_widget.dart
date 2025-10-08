import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';

class WeatherDetailsWidget extends StatelessWidget {
  final dynamic weather;
  final bool showAirQuality; // 是否显示空气质量（城市信息页面需要）

  const WeatherDetailsWidget({
    super.key,
    required this.weather,
    this.showAirQuality = false,
  });

  String _formatNumber(dynamic value) {
    if (value == null) return '--';
    if (value is String) {
      try {
        return value;
      } catch (e) {
        return '--';
      }
    }
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    if (weather?.current?.current == null) {
      return const SizedBox.shrink();
    }

    final current = weather.current.current;
    final air = weather?.current?.air ?? weather?.air;

    // 定义详细信息项
    final List<_DetailItem> detailItems = [];

    // 如果显示空气质量且有空气质量数据，添加到列表开头
    if (showAirQuality && air != null) {
      detailItems.add(
        _DetailItem(
          icon: Icons.air,
          label: '空气质量',
          value: '${_formatNumber(air.AQI)} (${air.levelIndex ?? '未知'})',
        ),
      );
      detailItems.add(
        _DetailItem(
          icon: Icons.thermostat,
          label: '体感温度',
          value: '${_formatNumber(current.feelstemperature)}℃',
        ),
      );
    }

    // 添加标准信息项
    detailItems.addAll([
      _DetailItem(
        icon: Icons.water_drop,
        label: '湿度',
        value: '${_formatNumber(current.humidity)}%',
      ),
      _DetailItem(
        icon: showAirQuality ? Icons.compress : Icons.air,
        label: '气压',
        value: '${_formatNumber(current.airpressure)}hpa',
      ),
      _DetailItem(
        icon: Icons.air,
        label: '风力',
        value: '${current.winddir ?? '--'} ${current.windpower ?? ''}',
      ),
      _DetailItem(
        icon: Icons.visibility,
        label: '能见度',
        value: '${_formatNumber(current.visibility)}km',
      ),
    ]);

    // 如果不显示空气质量，添加体感温度和天气状况
    if (!showAirQuality) {
      detailItems.addAll([
        _DetailItem(
          icon: Icons.wb_sunny,
          label: '体感温度',
          value: '${_formatNumber(current.feelstemperature)}℃',
        ),
        _DetailItem(
          icon: Icons.info,
          label: '天气状况',
          value: current.weather ?? '--',
        ),
      ]);
    }

    // 将数据分成两列（第一列：湿度、风力、体感温度；第二列：气压、能见度、天气状况）
    final List<_DetailItem> column1 = [];
    final List<_DetailItem> column2 = [];

    for (int i = 0; i < detailItems.length; i++) {
      if (i % 2 == 0) {
        column1.add(detailItems[i]);
      } else {
        column2.add(detailItems[i]);
      }
    }

    // 确保两列长度相同
    final int maxLen = math.max(column1.length, column2.length);
    while (column1.length < maxLen) {
      column1.add(_createPlaceholderItem());
    }
    while (column2.length < maxLen) {
      column2.add(_createPlaceholderItem());
    }

    // 构建行数据
    final List<List<_DetailItem>> rows = [];
    for (int i = 0; i < maxLen; i++) {
      rows.add([column1[i], column2[i]]);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.screenHorizontalPadding,
      ),
      child: Card(
        elevation: AppColors.cardElevation,
        shadowColor: AppColors.cardShadowColor,
        color: AppColors.materialCardColor,
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
                    color: AppColors.accentBlue,
                    size: AppConstants.sectionTitleIconSize,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '详细信息',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: AppConstants.sectionTitleFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 将详细信息项组织成2列
              Column(
                children: rows.map((row) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildCompactDetailItem(context, row[0], true),
                        ), // 第一列使用橙色
                        const SizedBox(width: 4),
                        Expanded(
                          child: _buildCompactDetailItem(
                            context,
                            row[1],
                            false,
                          ),
                        ), // 第二列使用绿色
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 创建占位符项
  _DetailItem _createPlaceholderItem() {
    return _DetailItem(icon: Icons.info, label: '', value: '');
  }

  Widget _buildCompactDetailItem(
    BuildContext context,
    _DetailItem item,
    bool isFirstColumn,
  ) {
    // 如果是占位符，返回空容器
    if (item.label == '' && item.value == '') {
      return const SizedBox();
    }

    // 根据所在列决定颜色
    Color iconColor = isFirstColumn
        ? const Color(0xFFFFB74D) // 第一列使用橙色
        : const Color(0xFF64DD17); // 第二列使用绿色（替换原来的蓝色）

    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    // 提高亮色模式下的清晰度
    final backgroundOpacity = themeProvider.isLightTheme ? 0.15 : 0.25;
    final iconBackgroundOpacity = themeProvider.isLightTheme ? 0.2 : 0.3;

    return Container(
      decoration: BoxDecoration(
        color: iconColor.withOpacity(backgroundOpacity), // 根据主题调整透明度
        borderRadius: BorderRadius.circular(4), // 与今日提醒保持一致
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(
                      iconBackgroundOpacity,
                    ), // 根据主题调整透明度
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    item.icon,
                    color: iconColor, // 使用图标颜色
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13, // 从11增大到13
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                    textAlign: TextAlign.left,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              item.value,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
              textAlign: TextAlign.left,
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailItem {
  final IconData icon;
  final String label;
  final String value;

  _DetailItem({required this.icon, required this.label, required this.value});
}
