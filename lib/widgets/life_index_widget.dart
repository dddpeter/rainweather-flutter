import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sun_moon_index_model.dart';
import '../providers/weather_provider.dart';
import '../providers/theme_provider.dart';
import '../constants/app_colors.dart';

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
                  style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('sunMoonData: ${sunMoonData != null ? "有数据" : "无数据"}', style: TextStyle(color: AppColors.textSecondary)),
                Text('index: ${sunMoonData?.index != null ? "有数据" : "无数据"}', style: TextStyle(color: AppColors.textSecondary)),
                Text('index长度: ${sunMoonData?.index?.length ?? 0}', style: TextStyle(color: AppColors.textSecondary)),
                Text('isLoading: ${weatherProvider.isLoadingSunMoonIndex}', style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          );
        }

        if (showContainer) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.cardBorder,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.eco,
                      color: AppColors.accentGreen,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '生活指数',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                lifeIndexContent,
              ],
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
    final targetIndices = [
      '穿衣指数', '感冒指数', '化妆指数', '紫外线强度指数', 
      '洗车指数', '运动指数'
    ];
    
    final filteredIndices = indices.where((index) => 
      targetIndices.contains(index.indexTypeCh ?? '')).toList();
    
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
              Expanded(
                child: _buildLifeIndexItem(row[0]),
              ),
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
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            lifeIndex.indexTypeCh ?? '',
            style: TextStyle(
              color: AppColors.textSecondary, // 使用主题色
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            lifeIndex.indexLevel ?? '--',
            style: TextStyle(
              color: AppColors.textPrimary, // 使用主题色，提高对比度
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            lifeIndex.indexContent ?? '',
            style: TextStyle(
              color: AppColors.textSecondary, // 使用主题色
              fontSize: 9,
              height: 1.1,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Color _getLifeIndexColor(String indexType) {
    return AppColors.accentGreen;
  }
}