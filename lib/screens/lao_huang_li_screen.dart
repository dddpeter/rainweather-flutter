import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../constants/app_colors.dart';
import '../services/lunar_service.dart';
import '../models/lunar_model.dart';
import 'lunar_calendar_screen.dart';
import '../widgets/lunar_detail_widget.dart';
import '../widgets/ai_interpretation_widget.dart';
// import '../widgets/typewriter_text_widget.dart'; // 已不再使用，注释掉

/// 老黄历详情页面（Swipe页面：黄历详情 + AI解读）
class LaoHuangLiScreen extends StatefulWidget {
  final DateTime? selectedDate;

  const LaoHuangLiScreen({super.key, this.selectedDate});

  @override
  State<LaoHuangLiScreen> createState() => _LaoHuangLiScreenState();
}

class _LaoHuangLiScreenState extends State<LaoHuangLiScreen>
    with SingleTickerProviderStateMixin {
  late DateTime _selectedDate;
  LunarInfo? _lunarInfo;
  final LunarService _lunarService = LunarService.getInstance();


  // Swipe页面相关
  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<double> _animation;
  int _currentPage = 0;
  final List<String> _pageTitles = [
    '黄历详情',
    'AI解读',
  ];


  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate ?? DateTime.now();
    _pageController = PageController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadLunarInfo();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    _animationController.reset();
    _animationController.forward();
    
  }

  void _loadLunarInfo() {
    try {
      setState(() {
        _lunarInfo = _lunarService.getLunarInfo(_selectedDate);
      });

    } catch (e) {
      print('❌ 加载农历信息失败: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        AppColors.setThemeProvider(themeProvider);

        return Container(
          decoration: BoxDecoration(
            gradient: AppColors.screenBackgroundGradient,
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              elevation: 4,
              backgroundColor: Colors.transparent,
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  // 半透明背景 - 基于主题色，已包含透明度
                  color: AppColors.appBarBackground,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(0.5),
                child: Container(
                  height: 0.5,
                  color: themeProvider.getColor('border').withOpacity(0.2),
                ),
              ),
              foregroundColor: themeProvider.isLightTheme
                  ? AppColors.primaryBlue
                  : AppColors.accentBlue,
              title: Text(
                '黄历详情',
                style: TextStyle(
                  color: themeProvider.isLightTheme
                      ? AppColors.primaryBlue
                      : AppColors.accentBlue,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: themeProvider.isLightTheme
                      ? AppColors.primaryBlue
                      : AppColors.accentBlue,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    Icons.calendar_today,
                    color: themeProvider.isLightTheme
                        ? AppColors.primaryBlue
                        : AppColors.accentBlue,
                  ),
                  onPressed: _selectDate,
                ),
              ],
            ),
            body: _lunarInfo == null
                ? Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryBlue,
                    ),
                  )
                : Column(
                    children: [
                      // 页面指示器
                      _buildPageIndicator(themeProvider),
                      
                      // 页面内容
                      Expanded(
                        child: PageView(
                          controller: _pageController,
                          onPageChanged: _onPageChanged,
                          children: [
                            _buildDetailPage(),
                            _buildInterpretationPage(themeProvider),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }


  /// 选择日期 - 使用农历日历页面
  Future<void> _selectDate() async {
    final DateTime? picked = await Navigator.push<DateTime>(
      context,
      MaterialPageRoute(
        builder: (context) => LunarCalendarScreen(
          initialDate: _selectedDate,
          isSelectMode: true, // 选择模式
        ),
      ),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadLunarInfo();
    }
  }

  /// 构建页面指示器
  Widget _buildPageIndicator(ThemeProvider themeProvider) {
    // 使用与 AppBar 图标一致的颜色
    final iconColor = themeProvider.isLightTheme
        ? AppColors.primaryBlue
        : AppColors.accentBlue;
    
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: AppColors.appBarBackground,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_pageTitles.length, (index) {
          final isSelected = index == _currentPage;
          return GestureDetector(
            onTap: () {
              if (!isSelected) {
                _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            },
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Container(
                  width: 90,
                  height: 32,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? iconColor.withOpacity(0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? iconColor.withOpacity(0.5)
                          : iconColor.withOpacity(0.3), // 未选中也使用主题色，提高可见度
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _pageTitles[index],
                        style: TextStyle(
                          color: isSelected
                              ? iconColor
                              : iconColor.withOpacity(0.7), // 未选中也使用主题色，提高可见度
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        }),
      ),
    );
  }

  /// 构建黄历详情页面
  Widget _buildDetailPage() {
    return LunarDetailWidget(
      selectedDate: _selectedDate,
      lunarInfo: _lunarInfo!,
    );
  }

  /// 构建AI解读页面
  Widget _buildInterpretationPage(ThemeProvider themeProvider) {
    return AIInterpretationWidget(
      selectedDate: _selectedDate,
      lunarInfo: _lunarInfo!,
    );
  }

}
