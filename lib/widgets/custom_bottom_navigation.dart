import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/theme_provider.dart';

class CustomBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<BottomNavigationItem> items;

  const CustomBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final mediaQuery = MediaQuery.of(context);
        final bottomPadding = mediaQuery.padding.bottom;
    
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
        minimum: EdgeInsets.only(bottom: bottomPadding > 0 ? 0 : 4),
        child: Container(
          height: 56 + (bottomPadding > 0 ? 0 : 4),
          padding: EdgeInsets.symmetric(
            horizontal: 8, 
            vertical: bottomPadding > 0 ? 4 : 2,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isSelected = currentIndex == index;

              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(index),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? AppColors.bottomNavSelectedBackground 
                          : AppColors.bottomNavUnselectedBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          item.icon,
                          color: isSelected 
                              ? AppColors.bottomNavSelectedColor 
                              : AppColors.bottomNavUnselectedColor,
                          size: 22,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.label,
                          style: TextStyle(
                            color: isSelected 
                                ? AppColors.bottomNavSelectedColor 
                                : AppColors.bottomNavUnselectedColor,
                            fontSize: 10,
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
