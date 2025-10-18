import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_version.dart';
import '../providers/weather_provider.dart';
import '../utils/app_state_manager.dart';
import '../main.dart';

/// 应用启动页面 - 支持根据应用主题切换颜色
class AppSplashScreen extends StatefulWidget {
  const AppSplashScreen({super.key});

  @override
  State<AppSplashScreen> createState() => _AppSplashScreenState();
}

class _AppSplashScreenState extends State<AppSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeApp();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600), // 从1500ms缩短到600ms
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOut), // 改为easeOut，更快
      ),
    );

    _animationController.forward();
  }

  Future<void> _initializeApp() async {
    try {
      // 等待动画开始（缩短到200ms）
      await Future.delayed(const Duration(milliseconds: 200));

      if (!mounted) return;

      // 使用快速启动模式：先加载缓存数据，后台刷新
      final weatherProvider = Provider.of<WeatherProvider>(
        context,
        listen: false,
      );

      print('🚀 启动流程: 使用快速启动模式');
      await weatherProvider.quickStart();

      if (!mounted) return;

      // 等待动画完成（缩短到400ms）
      await Future.delayed(const Duration(milliseconds: 400));

      if (mounted) {
        // 标记应用完全启动
        await AppStateManager().markAppFullyStarted();

        // 跳转到主界面（此时已显示缓存数据，后台正在刷新）
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const MainScreen()),
            (Route<dynamic> route) => false,
          );
        }

        print('✅ 启动完成，界面已显示（后台继续刷新数据）');
      }
    } catch (e) {
      print('❌ 启动初始化失败: $e');
      // 即使失败也跳转到主界面
      if (mounted) {
        // 标记应用完全启动（即使初始化失败）
        await AppStateManager().markAppFullyStarted();

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainScreen()),
          (Route<dynamic> route) => false,
        );
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // 固定使用暗色主题渐变
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF012d78), // 深蓝色
              Color(0xFF0A1B3D), // 深蓝黑色
            ],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 应用图标
                      Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            'assets/images/app_icon.png',
                            width: 160,
                            height: 160,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              // 如果图片加载失败，显示占位符
                              return const Icon(
                                Icons.cloud,
                                size: 80,
                                color: Colors.white, // 固定白色
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      // 应用名称
                      Text(
                        AppVersion.appName,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white, // 固定白色
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // 应用描述
                      Text(
                        '智能天气预报应用',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.8), // 固定半透明白色
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 50),
                      // 加载指示器
                      const SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white, // 固定白色
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
