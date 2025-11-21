import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/theme_provider.dart';

class CustomBottomNavigationV2 extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<BottomNavigationItem> items;

  const CustomBottomNavigationV2({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Container(
          decoration: BoxDecoration(
            // 亮色模式使用浅蓝色，暗色模式使用深色
            color: AppColors.appBarBackground,
            boxShadow: [
              BoxShadow(
                color: AppColors.borderColor.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Container(
              height: 80, // Material Design 3 推荐高度
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isSelected = currentIndex == index;

                  return Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => onTap(index),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 12,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // 图标容器，选中时有背景
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                decoration: isSelected
                                    ? BoxDecoration(
                                        color:
                                            (themeProvider.isLightTheme
                                                    ? AppColors.primaryBlue
                                                    : AppColors
                                                          .accentBlue) // 暗色模式使用更亮的强调色
                                                .withOpacity(
                                                  themeProvider.isLightTheme
                                                      ? 0.12
                                                      : 0.24,
                                                ),
                                        borderRadius: BorderRadius.circular(16),
                                      )
                                    : null,
                                child: Icon(
                                  item.icon,
                                  color: isSelected
                                      ? (themeProvider.isLightTheme
                                            ? AppColors.primaryBlue
                                            : AppColors
                                                  .accentBlue) // 暗色模式使用更亮的强调色
                                      : AppColors.textTertiary,
                                  size: 24, // Material Design 3 标准图标大小
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.label,
                                style: TextStyle(
                                  color: isSelected
                                      ? (themeProvider.isLightTheme
                                            ? AppColors.primaryBlue
                                            : AppColors
                                                  .accentBlue) // 暗色模式使用更亮的强调色
                                      : AppColors.textTertiary,
                                  fontSize: 12, // Material Design 3 标准字号
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  letterSpacing: 0.1,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
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

  const BottomNavigationItem({required this.icon, required this.label});
}
