import 'package:flutter/material.dart';
import '../models/weather_model.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../utils/weather_icon_helper.dart';

/// 空气质量卡片组件
/// 显示AQI数值、等级、标尺和等级说明
class AirQualityCard extends StatelessWidget {
  final WeatherModel? weather;

  const AirQualityCard({super.key, required this.weather});

  @override
  Widget build(BuildContext context) {
    final air = weather?.current?.air ?? weather?.air;

    if (air == null) {
      return const SizedBox.shrink();
    }

    final aqi = int.tryParse(air.AQI ?? '');
    if (aqi == null) {
      return const SizedBox.shrink();
    }

    final level =
        air.levelIndex ?? WeatherIconHelper.getAirQualityLevelText(aqi);
    final color = WeatherIconHelper.getAirQualityColor(aqi);

    // 计算标尺位置（0-500范围）
    final progress = (aqi / 500).clamp(0.0, 1.0);

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
              // 标题行
              Row(
                children: [
                  Icon(
                    Icons.air,
                    color: color,
                    size: AppConstants.sectionTitleIconSize,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '空气质量',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: AppConstants.sectionTitleFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  // AQI数值（缩小尺寸，与后面文字高度一致）
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$aqi',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    level,
                    style: TextStyle(
                      color: color,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 空气质量标尺
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标尺背景和进度
                  Stack(
                    children: [
                      // 彩色渐变背景（6段）
                      Container(
                        height: 12,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.airExcellent, // 优 0-50
                              AppColors.airGood, // 良 50-100
                              AppColors.airLight, // 轻度污染 100-150
                              AppColors.airModerate, // 中度污染 150-200
                              AppColors.airHeavy, // 重度污染 200-300
                              AppColors.airSevere, // 严重污染 300-500
                            ],
                            stops: [0.0, 0.1, 0.2, 0.4, 0.6, 1.0],
                          ),
                        ),
                      ),
                      // 当前位置指示器
                      Positioned(
                        left:
                            progress * (MediaQuery.of(context).size.width - 64),
                        top: -4,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: color, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // 刻度标签
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildScaleLabel('0'),
                      _buildScaleLabel('50'),
                      _buildScaleLabel('100'),
                      _buildScaleLabel('150'),
                      _buildScaleLabel('200'),
                      _buildScaleLabel('300+'),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 等级说明 - 平均分布占满一行
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: _buildLevelTag('优', AppColors.airExcellent)),
                  const SizedBox(width: 4),
                  Expanded(child: _buildLevelTag('良', AppColors.airGood)),
                  const SizedBox(width: 4),
                  Expanded(child: _buildLevelTag('轻度', AppColors.airLight)),
                  const SizedBox(width: 4),
                  Expanded(child: _buildLevelTag('中度', AppColors.airModerate)),
                  const SizedBox(width: 4),
                  Expanded(child: _buildLevelTag('重度', AppColors.airHeavy)),
                  const SizedBox(width: 4),
                  Expanded(child: _buildLevelTag('严重', AppColors.airSevere, isSevere: true)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建刻度标签
  Widget _buildScaleLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 10,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  /// 构建等级标签
  Widget _buildLevelTag(String text, Color color, {bool isSevere = false}) {
    // 对于"严重"等级，统一使用基础紫色，通过透明度调整明暗
    final tagColor = isSevere
        ? AppColors.airSevere // 统一使用 Material Purple 700
        : color;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: tagColor.withOpacity(0.2), // 统一透明度
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: tagColor.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: tagColor,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          height: 1.0,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
