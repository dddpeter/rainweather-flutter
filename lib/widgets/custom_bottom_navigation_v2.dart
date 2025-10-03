import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/theme_provider.dart';

class CustomBottomNavigationV2 extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<BottomNavigationItem> items;

  const CustomBottomNavigationV2({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        border: Border(
          top: BorderSide(
            color: AppColors.borderColor,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Container(
          constraints: const BoxConstraints(minHeight: 70), // 调整最小高度
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), // 调整内边距
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isSelected = currentIndex == index;

              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(index),
                  behavior: HitTestBehavior.opaque, // 确保整个区域都可以点击
                  child: Container(
                    // 增加触控区域，让整个容器都可以点击
                    constraints: const BoxConstraints(minHeight: 60), // 使用最小高度而不是固定高度
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6), // 调整内边距
                    margin: const EdgeInsets.symmetric(horizontal: 4), // 增加水平边距
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          item.icon,
                          color: isSelected 
                              ? AppColors.primaryBlue
                              : AppColors.textTertiary,
                          size: 22, // 稍微减小图标
                        ),
                        const SizedBox(height: 2), // 减小间距
                        Text(
                          item.label,
                          style: TextStyle(
                            color: isSelected 
                                ? AppColors.primaryBlue
                                : AppColors.textTertiary,
                            fontSize: 10, // 稍微减小字体
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
      },
    );
  }
}

class BottomNavigationItem {
  final IconData icon;
  final String label;

  const BottomNavigationItem({
    required this.icon,
    required this.label,
  });
}
