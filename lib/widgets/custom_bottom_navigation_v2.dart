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
        final activeColor = themeProvider.isLightTheme
            ? AppColors.primaryBlue
            : const Color(0xFF8edafc);

        return Container(
          decoration: BoxDecoration(
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
            top: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isSelected = currentIndex == index;

                return Expanded(
                  child: Semantics(
                    label: item.label,
                    selected: isSelected,
                    button: true,
                    hint: isSelected ? '当前选中${item.label}' : '切换到${item.label}',
                    child: InkWell(
                      onTap: () => onTap(index),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? activeColor.withOpacity(0.15) : Colors.transparent,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 150),
                              child: Icon(
                                item.icon,
                                key: ValueKey(isSelected),
                                color: isSelected ? activeColor : AppColors.textTertiary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(height: 2),
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 150),
                              style: TextStyle(
                                color: isSelected ? activeColor : AppColors.textTertiary,
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                ),
                                child: Text(item.label),
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
