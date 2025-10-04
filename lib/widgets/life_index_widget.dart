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
                padding: const EdgeInsets.all(16),
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
                    const SizedBox(height: 16),
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
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Expanded(child: _buildLifeIndexItem(row[0])),
              const SizedBox(width: 8),
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

    return Card(
      elevation: 0,
      color: color.withOpacity(0.08),
      surfaceTintColor: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    lifeIndex.indexTypeCh ?? '',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lifeIndex.indexLevel ?? '--',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lifeIndex.indexContent ?? '',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
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
    return AppColors.accentGreen;
  }
}
