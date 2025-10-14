import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../constants/app_colors.dart';

/// 浮动操作岛 - 支持展开多个操作按钮
///
/// 特性：
/// 1. 收起时显示主图标
/// 2. 点击展开显示多个操作
/// 3. 优雅的展开/收起动画
/// 4. 每个页面可定制不同操作
class FloatingActionIsland extends StatefulWidget {
  final List<IslandAction> actions; // 操作列表
  final IconData mainIcon; // 主图标（收起时显示）
  final String? mainTooltip; // 主图标提示

  const FloatingActionIsland({
    super.key,
    required this.actions,
    this.mainIcon = Icons.menu,
    this.mainTooltip,
  });

  @override
  State<FloatingActionIsland> createState() => _FloatingActionIslandState();
}

class _FloatingActionIslandState extends State<FloatingActionIsland>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  bool _isScrolling = false;
  Timer? _scrollTimer;
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.125,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// 处理滚动开始
  void _onScrollStart() {
    _scrollTimer?.cancel();
    if (!_isScrolling && mounted) {
      setState(() {
        _isScrolling = true;
      });
    }
  }

  /// 处理滚动结束
  void _onScrollEnd() {
    _scrollTimer?.cancel();
    _scrollTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isScrolling = false;
        });
      }
    });
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      print('🏝️ 浮动岛状态切换: ${_isExpanded ? "展开" : "收起"}');
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();

    print('🏝️ FloatingActionIsland build: 接收到 ${widget.actions.length} 个操作');
    print('🏝️ 展开状态: $_isExpanded');

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollStartNotification) {
          _onScrollStart();
        } else if (notification is ScrollEndNotification) {
          _onScrollEnd();
        }
        return false;
      },
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          // 遮罩层（展开时显示）
          if (_isExpanded)
            GestureDetector(
              onTap: _toggle,
              child: AnimatedOpacity(
                opacity: _isExpanded ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Container(color: Colors.black.withOpacity(0.3)),
              ),
            ),

          // 操作按钮列表（从下往上展开）
          Positioned(
            right: 4,
            bottom: 56, // 主按钮上方
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: () {
                print('🔢 开始生成 ${widget.actions.length} 个操作按钮...');
                final buttons = List.generate(
                  widget.actions.length,
                  (index) => _buildActionButton(
                    widget.actions[index],
                    index,
                    themeProvider,
                  ),
                ).reversed.toList();
                print('✅ 操作按钮生成完成，共 ${buttons.length} 个');
                return buttons;
              }(),
            ),
          ),

          // 主按钮（收起/展开控制）
          Positioned(
            right: 0,
            bottom: 0, // 接近底部导航栏上方
            child: _buildMainButton(themeProvider),
          ),
        ],
      ),
    );
  }

  /// 构建主按钮
  Widget _buildMainButton(ThemeProvider themeProvider) {
    return GestureDetector(
      onTap: _toggle,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          // 透明度计算：
          // 展开时：1.0（完全不透明）
          // 收起且滚动时：0.2（淡化但可见）
          // 收起且静止时：0.6（易于识别，对老人友好）
          double opacity;
          if (_isExpanded) {
            opacity = 1.0;
          } else if (_isScrolling) {
            opacity = 0.2; // 滚动时淡化但保持可见
          } else {
            opacity = 0.6; // 静止时清晰可见，对老人友好
          }

          return AnimatedOpacity(
            opacity: opacity,
            duration: const Duration(milliseconds: 300),
            child: RotationTransition(
              turns: _rotationAnimation,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryBlue.withOpacity(0.95),
                      AppColors.primaryBlue.withOpacity(0.85),
                    ],
                  ),
                  shape: BoxShape.circle, // 圆形
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryBlue.withOpacity(0.5),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Icon(
                  _isExpanded ? Icons.close : widget.mainIcon,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// 构建操作按钮
  Widget _buildActionButton(
    IslandAction action,
    int index,
    ThemeProvider themeProvider,
  ) {
    final buttonBgColor = action.backgroundColor ?? AppColors.primaryBlue;

    print('🔘 创建操作按钮 #$index: ${action.label}');

    return ScaleTransition(
      scale: _expandAnimation,
      child: FadeTransition(
        opacity: _expandAnimation,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 标签（可选）
              if (action.label != null)
                AnimatedOpacity(
                  opacity: _isExpanded ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      // 暗色模式：标签背景和图标背景一致
                      // 亮色模式：使用卡片背景色
                      color: themeProvider.isLightTheme
                          ? AppColors.materialCardColor
                          : buttonBgColor.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      action.label!,
                      style: TextStyle(
                        color: themeProvider.isLightTheme
                            ? AppColors.textPrimary
                            : Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

              // 按钮
              GestureDetector(
                onTap: () {
                  _toggle(); // 收起操作岛
                  action.onTap(); // 执行操作
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: buttonBgColor.withOpacity(0.95), // 半透明效果
                    shape: BoxShape.circle, // 圆形
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: buttonBgColor.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                        spreadRadius: 1,
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.15),
                        blurRadius: 6,
                        offset: const Offset(0, 1),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Icon(
                    action.icon,
                    color: Colors.white, // 统一白色图标
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 操作岛动作定义
class IslandAction {
  final IconData icon; // 图标
  final String? label; // 标签文字（可选）
  final VoidCallback onTap; // 点击回调
  final Color? backgroundColor; // 背景色（可选）
  final Color? iconColor; // 图标颜色（可选）

  const IslandAction({
    required this.icon,
    required this.onTap,
    this.label,
    this.backgroundColor,
    this.iconColor,
  });
}
