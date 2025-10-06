import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/theme_provider.dart';

/// 城市卡片骨架屏组件 - 支持主题切换
class CityCardSkeleton extends StatelessWidget {
  const CityCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        // 确保AppColors使用最新的主题
        AppColors.setThemeProvider(themeProvider);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder, width: 1),
          ),
          child: _buildSkeletonContent(themeProvider.isLightTheme),
        );
      },
    );
  }

  Widget _buildSkeletonContent(bool isLightTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // 城市名称骨架
            _SkeletonBox(
              width: 100,
              height: 24,
              borderRadius: 4,
              isLightTheme: isLightTheme,
            ),
            const Spacer(),
            // 温度骨架
            _SkeletonBox(
              width: 80,
              height: 28,
              borderRadius: 4,
              isLightTheme: isLightTheme,
            ),
          ],
        ),
        const SizedBox(height: 12),
        // 天气描述骨架
        _SkeletonBox(
          width: 120,
          height: 16,
          borderRadius: 4,
          isLightTheme: isLightTheme,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // 天气图标骨架
            _SkeletonBox(
              width: 40,
              height: 40,
              borderRadius: 20,
              isLightTheme: isLightTheme,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SkeletonBox(
                  width: 100,
                  height: 14,
                  borderRadius: 4,
                  isLightTheme: isLightTheme,
                ),
                const SizedBox(height: 4),
                _SkeletonBox(
                  width: 80,
                  height: 14,
                  borderRadius: 4,
                  isLightTheme: isLightTheme,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

/// 骨架屏基础盒子组件（带闪烁动画）- 支持主题切换
class _SkeletonBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final bool isLightTheme;

  const _SkeletonBox({
    required this.width,
    required this.height,
    required this.borderRadius,
    required this.isLightTheme,
  });

  @override
  State<_SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<_SkeletonBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.3,
      end: 0.7,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 根据主题选择合适的颜色
    final baseColor = widget.isLightTheme
        ? Colors.grey[300]! // 浅色主题：浅灰色
        : Colors.grey[700]!; // 深色主题：深灰色

    final shimmerColor = widget.isLightTheme
        ? Colors.grey[100]! // 浅色主题：更浅的灰色
        : Colors.grey[600]!; // 深色主题：稍浅的灰色

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.transparent,
                  shimmerColor.withOpacity(_animation.value * 0.5),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
              borderRadius: BorderRadius.circular(widget.borderRadius),
            ),
          ),
        );
      },
    );
  }
}

/// 骨架屏列表组件（显示多个骨架卡片）
class CityCardSkeletonList extends StatelessWidget {
  final int itemCount;

  const CityCardSkeletonList({super.key, this.itemCount = 3});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return const CityCardSkeleton();
      },
    );
  }
}
