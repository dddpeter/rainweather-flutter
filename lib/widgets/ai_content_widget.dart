import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';

/// AI内容组件 - 支持渐进式展示
///
/// 特性：
/// 1. 立即显示卡片框架
/// 2. 骨架屏加载动画
/// 3. AI内容渐入动画
/// 4. 失败降级 + 重试按钮
class AIContentWidget extends StatefulWidget {
  final String title;
  final IconData icon;
  final Future<String> Function() fetchAIContent;
  final String defaultContent; // 降级内容
  final VoidCallback? onRefresh; // 刷新回调（可选）
  final bool useCustomStyle; // 是否使用自定义样式（今日天气页面特殊样式）
  final String? cityName; // 城市名称，用于区分不同城市的AI内容

  const AIContentWidget({
    super.key,
    required this.title,
    required this.icon,
    required this.fetchAIContent,
    required this.defaultContent,
    this.onRefresh,
    this.useCustomStyle = false, // 默认使用标准卡片样式
    this.cityName, // 添加城市名称参数
  });

  @override
  State<AIContentWidget> createState() => _AIContentWidgetState();
}

class _AIContentWidgetState extends State<AIContentWidget> {
  String? _content; // AI内容
  bool _isLoading = true; // 加载状态
  bool _hasError = false; // 错误状态
  bool _isTimeout = false; // 超时状态

  @override
  void initState() {
    super.initState();
    _loadAIContent();
  }

  @override
  void didUpdateWidget(covariant AIContentWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // ⚠️ 只比较 cityName，不要比较 fetchAIContent（函数引用每次都不同）
    // 避免无限循环重新加载
    if (oldWidget.cityName != widget.cityName) {
      print(
        '🔄 AIContentWidget: 城市变化 ${oldWidget.cityName} -> ${widget.cityName}，重新加载',
      );
      _loadAIContent();
    }
  }

  Future<void> _loadAIContent() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _isTimeout = false;
    });

    try {
      final content = await widget.fetchAIContent().timeout(
        const Duration(seconds: 15),
      );

      if (mounted) {
        setState(() {
          _content = content;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          // 判断是否为超时错误
          if (e.toString().contains('TimeoutException') ||
              e.toString().contains('timeout')) {
            _isTimeout = true;
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.screenHorizontalPadding,
      ),
      child: Card(
        elevation: AppColors.cardElevation,
        shadowColor: AppColors.cardShadowColor,
        color: AppColors.materialCardColor,
        surfaceTintColor: Colors.transparent,
        shape: AppColors.cardShape,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题栏（立即显示）
              Row(
                children: [
                  Icon(
                    widget.icon,
                    color: AppColors.accentBlue,
                    size: AppConstants.sectionTitleIconSize,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.title,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: AppConstants.sectionTitleFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  // AI标签
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color:
                          (themeProvider.isLightTheme
                                  ? const Color(0xFF004CFF)
                                  : const Color(0xFFFFB300))
                              .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          color: themeProvider.isLightTheme
                              ? const Color(0xFF004CFF)
                              : const Color(0xFFFFB300),
                          size: 10,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          'AI',
                          style: TextStyle(
                            color: themeProvider.isLightTheme
                                ? const Color(0xFF004CFF)
                                : const Color(0xFFFFB300),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 内容区域（渐进式显示）
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: _buildContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      // 加载状态：显示骨架屏
      return _buildSkeletonLoading();
    } else if (_hasError) {
      // 错误状态：根据是否为超时显示不同内容
      return _buildErrorState();
    } else {
      // 成功状态：显示AI内容（带渐入动画）
      return _buildAIContent();
    }
  }

  /// 骨架屏加载动画
  Widget _buildSkeletonLoading() {
    return Column(
      key: const ValueKey('loading'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSkeletonLine(width: double.infinity, height: 14),
        const SizedBox(height: 8),
        _buildSkeletonLine(width: double.infinity, height: 14),
        const SizedBox(height: 8),
        _buildSkeletonLine(width: 250, height: 14),
        const SizedBox(height: 8),
        _buildSkeletonLine(width: 180, height: 14),
      ],
    );
  }

  Widget _buildSkeletonLine({required double width, required double height}) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1500),
      // ⚠️ 使用无限循环动画，避免使用 onEnd + setState 导致过多的重建
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: AppColors.textSecondary.withValues(alpha: 0.1),
        ),
      ),
      builder: (context, value, child) {
        return Opacity(
          opacity: 0.3 + (value * 0.7), // 0.3 -> 1.0 循环闪烁
          child: child,
        );
      },
    );
  }

  /// AI内容显示（渐入动画）
  Widget _buildAIContent() {
    return TweenAnimationBuilder<double>(
      key: const ValueKey('content'),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - value)), // 从下往上渐入
            child: child,
          ),
        );
      },
      child: Text(
        _content ?? widget.defaultContent,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          height: 1.5,
        ),
      ),
    );
  }

  /// 错误状态（显示重试按钮）
  Widget _buildErrorState() {
    return Column(
      key: const ValueKey('error'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 根据是否为超时显示不同内容
        if (_isTimeout)
          // 超时状态：显示"暂未获取到结果"
          Text(
            '暂未获取到结果',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          )
        else
          // 其他错误：显示默认内容
          Text(
            widget.defaultContent,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            TextButton.icon(
              onPressed: _loadAIContent,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('重新生成'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryBlue,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
