import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sun_moon_index_model.dart';
import '../providers/weather_provider.dart';
import '../providers/theme_provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';

class LifeIndexWidget extends StatelessWidget {
  final WeatherProvider weatherProvider;
  final bool showContainer;

  const LifeIndexWidget({
    Key? key,
    required this.weatherProvider,
    this.showContainer = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final sunMoonData = weatherProvider.sunMoonIndexData;

        // 生活指数信息
        Widget lifeIndexContent;
        if (sunMoonData?.index != null && sunMoonData!.index!.isNotEmpty) {
          lifeIndexContent = _buildLifeIndexGrid(context, sunMoonData.index!);
        } else {
          // 调试信息：显示为什么没有生活指数数据
          lifeIndexContent = Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Text(
                  '调试信息：生活指数数据',
                  style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'sunMoonData: ${sunMoonData != null ? "有数据" : "无数据"}',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                Text(
                  'index: ${sunMoonData?.index != null ? "有数据" : "无数据"}',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                Text(
                  'index长度: ${sunMoonData?.index?.length ?? 0}',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                Text(
                  'isLoading: ${weatherProvider.isLoadingSunMoonIndex}',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          );
        }

        if (showContainer) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              elevation: AppColors.cardElevation,
              shadowColor: AppColors.cardShadowColor,
              color: AppColors.materialCardColor,
              shape: AppColors.cardShape,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.eco,
                          color: AppColors.accentGreen,
                          size: AppConstants.sectionTitleIconSize,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '生活指数',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: AppConstants.sectionTitleFontSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    lifeIndexContent,
                  ],
                ),
              ),
            ),
          );
        } else {
          return lifeIndexContent;
        }
      },
    );
  }

  Widget _buildLifeIndexGrid(BuildContext context, List<LifeIndex> indices) {
    // 过滤出需要显示的生活指数
    final targetIndices = ['穿衣指数', '感冒指数', '化妆指数', '紫外线强度指数', '洗车指数', '运动指数'];

    final filteredIndices = indices
        .where((index) => targetIndices.contains(index.indexTypeCh ?? ''))
        .toList();

    print('原始指数数量: ${indices.length}');
    print('过滤后指数数量: ${filteredIndices.length}');
    print('原始指数类型: ${indices.map((e) => e.indexTypeCh).toList()}');
    print('过滤后指数类型: ${filteredIndices.map((e) => e.indexTypeCh).toList()}');

    // 将数据分成两列
    final List<List<LifeIndex>> rows = [];
    for (int i = 0; i < filteredIndices.length; i += 2) {
      rows.add([
        filteredIndices[i],
        if (i + 1 < filteredIndices.length) filteredIndices[i + 1],
      ]);
    }

    return Column(
      children: rows.map((row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 4), // 减小间隙
          child: Row(
            children: [
              Expanded(child: _buildLifeIndexItem(row[0])),
              const SizedBox(width: 4), // 减小间隙
              Expanded(
                child: row.length > 1
                    ? _buildLifeIndexItem(row[1])
                    : const SizedBox(), // 如果只有一项，用空容器占位
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLifeIndexItem(LifeIndex lifeIndex) {
    Color color = _getLifeIndexColor(lifeIndex.indexTypeCh ?? '');
    IconData icon = _getLifeIndexIcon(lifeIndex.indexTypeCh ?? '');

    return Builder(
      builder: (context) => InkWell(
        onTap: () => _showLifeIndexDialog(context, lifeIndex),
        borderRadius: BorderRadius.circular(8),
        child: Card(
          elevation: 0,
          color: color.withOpacity(0.25), // 内层小卡片: 0.4 × 0.618 ≈ 0.25
          surfaceTintColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                        color: AppColors
                            .cardThemeBlueIconBackgroundColor, // 使用主题蓝色图标背景
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        icon,
                        color: AppColors.cardThemeBlueIconColor, // 使用主题蓝色图标颜色
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _truncateIndexName(lifeIndex.indexTypeCh ?? ''),
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13, // 与详细信息卡片一致
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
                  lifeIndex.indexLevel ?? '--',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getLifeIndexIcon(String indexType) {
    switch (indexType) {
      case '穿衣指数':
        return Icons.checkroom;
      case '感冒指数':
        return Icons.local_hospital;
      case '化妆指数':
        return Icons.face;
      case '紫外线强度指数':
        return Icons.wb_sunny;
      case '洗车指数':
        return Icons.local_car_wash;
      case '运动指数':
        return Icons.directions_run;
      default:
        return Icons.info_outline;
    }
  }

  Color _getLifeIndexColor(String indexType) {
    return AppColors.cardThemeBlue; // 使用主题蓝色
  }

  /// 截断指标名称，最多显示5个字，超过则去掉末尾的"指数"
  String _truncateIndexName(String name) {
    if (name.length <= 5) {
      return name;
    }

    // 如果以"指数"结尾，去掉"指数"两个字
    if (name.endsWith('指数')) {
      String withoutSuffix = name.substring(0, name.length - 2);
      // 如果去掉"指数"后仍然超过5个字，则截断到5个字
      if (withoutSuffix.length > 5) {
        return withoutSuffix.substring(0, 5);
      }
      return withoutSuffix;
    }

    // 如果不以"指数"结尾，直接截断到5个字
    return name.substring(0, 5);
  }

  void _showLifeIndexDialog(BuildContext context, LifeIndex lifeIndex) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.backgroundSecondary,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.detailCardGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getLifeIndexIcon(lifeIndex.indexTypeCh ?? ''),
                  color: AppColors.detailCardGreen,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  lifeIndex.indexTypeCh ?? '生活指数',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.detailCardGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.detailCardGreen.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '指数等级',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      lifeIndex.indexLevel ?? '--',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (lifeIndex.indexContent != null &&
                  lifeIndex.indexContent!.isNotEmpty) ...[
                Text(
                  '详细说明',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  lifeIndex.indexContent!,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }
}
