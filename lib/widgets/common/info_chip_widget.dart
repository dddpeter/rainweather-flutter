import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';

/// 信息标签组件
/// 
/// 用于显示天气详情中的各项指标（湿度、风力、气压等）
class InfoChipWidget extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? backgroundColor;
  final Color? iconColor;
  final Color? textColor;
  final double height;
  final double iconSize;
  final double fontSize;

  const InfoChipWidget({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.backgroundColor,
    this.iconColor,
    this.textColor,
    this.height = 60,
    this.iconSize = 14,
    this.fontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: iconColor ?? themeProvider.getColor('headerTextSecondary'),
                size: iconSize,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: textColor ?? themeProvider.getColor('headerTextSecondary'),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: textColor ?? themeProvider.getColor('headerTextSecondary'),
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// 天气信息行组件
/// 
/// 用于显示一行多个信息标签
class WeatherInfoRow extends StatelessWidget {
  final List<InfoChipData> items;
  final double spacing;

  const WeatherInfoRow({
    super.key,
    required this.items,
    this.spacing = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: items
          .map((item) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: item == items.last ? 0 : spacing,
                  ),
                  child: InfoChipWidget(
                    icon: item.icon,
                    label: item.label,
                    value: item.value,
                  ),
                ),
              ))
          .toList(),
    );
  }
}

/// 信息标签数据
class InfoChipData {
  final IconData icon;
  final String label;
  final String value;

  const InfoChipData({
    required this.icon,
    required this.label,
    required this.value,
  });
}
