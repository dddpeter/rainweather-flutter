import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../constants/app_colors.dart';

/// 天气图标测试页面
class WeatherIconsTestScreen extends StatefulWidget {
  const WeatherIconsTestScreen({super.key});

  @override
  State<WeatherIconsTestScreen> createState() => _WeatherIconsTestScreenState();
}

class _WeatherIconsTestScreenState extends State<WeatherIconsTestScreen> {
  String _selectedCategory = '雨天';
  String _searchQuery = '';

  // 图标分类数据
  final Map<String, List<WeatherIconInfo>> _iconCategories = {
    '雨天': [
      WeatherIconInfo('毛毛雨', 'assets/images/毛毛雨.png', '轻微降水'),
      WeatherIconInfo('小雨', 'assets/images/小雨.png', '小量降水'),
      WeatherIconInfo('中雨', 'assets/images/中雨.png', '中等降水'),
      WeatherIconInfo('大雨', 'assets/images/大雨.png', '大量降水'),
      WeatherIconInfo('大暴雨', 'assets/images/大暴雨.png', '暴雨级降水'),
      WeatherIconInfo('特大暴雨', 'assets/images/特大暴雨.png', '特大暴雨'),
      WeatherIconInfo('强阵雨', 'assets/images/强阵雨.png', '强阵雨'),
      WeatherIconInfo('晴转小雨夹雪', 'assets/images/晴转小雨夹雪.png', '雨雪天气'),
    ],
    '雪天': [
      WeatherIconInfo('小雪', 'assets/images/小雪.png', '小量降雪'),
      WeatherIconInfo('中雪', 'assets/images/中雪.png', '中等降雪'),
      WeatherIconInfo('大雪', 'assets/images/大雪.png', '大量降雪'),
      WeatherIconInfo('暴雪', 'assets/images/暴雪.png', '暴雪级降雪'),
      WeatherIconInfo('大暴雪', 'assets/images/大暴雪.png', '大暴雪'),
      WeatherIconInfo('吹雪', 'assets/images/吹雪.png', '吹雪天气'),
      WeatherIconInfo('雨夹雪', 'assets/images/雨夹雪.png', '雨雪混合'),
      WeatherIconInfo('雪转晴', 'assets/images/雪转晴.png', '雪转晴天'),
    ],
    '晴天': [
      WeatherIconInfo('晴', 'assets/images/晴.png', '晴朗天气'),
      WeatherIconInfo('晴间多云', 'assets/images/晴间多云.png', '晴间多云'),
      WeatherIconInfo('多云', 'assets/images/多云.png', '多云天气'),
      WeatherIconInfo('多云转晴', 'assets/images/多云转晴.png', '多云转晴'),
      WeatherIconInfo('阴天', 'assets/images/阴天.png', '阴天天气'),
    ],
    '其他': [
      WeatherIconInfo('雾', 'assets/images/雾.png', '雾天天气'),
      WeatherIconInfo('浓雾', 'assets/images/浓雾.png', '浓雾天气'),
      WeatherIconInfo('霾', 'assets/images/霾.png', '霾天天气'),
      WeatherIconInfo('中度霾', 'assets/images/中度霾.png', '中度霾'),
      WeatherIconInfo('重度霾', 'assets/images/重度霾.png', '重度霾'),
      WeatherIconInfo('严重霾', 'assets/images/严重霾.png', '严重霾'),
      WeatherIconInfo('沙尘暴', 'assets/images/沙尘暴.png', '沙尘天气'),
      WeatherIconInfo('浮尘', 'assets/images/浮尘.png', '浮尘天气'),
      WeatherIconInfo('冰雹', 'assets/images/冰雹.png', '冰雹天气'),
      WeatherIconInfo('雨凇', 'assets/images/雨凇.png', '雨凇天气'),
      WeatherIconInfo('高温', 'assets/images/高温.png', '高温天气'),
      WeatherIconInfo('低温', 'assets/images/低温.png', '低温天气'),
    ],
  };

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
                '天气图标测试',
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
                    Icons.info_outline,
                    color: themeProvider.isLightTheme
                        ? AppColors.primaryBlue
                        : AppColors.accentBlue,
                  ),
                  onPressed: _showInfoDialog,
                ),
              ],
            ),
            body: Column(
              children: [
            // 搜索栏
            _buildSearchBar(),

            // 分类选择
            _buildCategorySelector(),

                // 图标网格
                Expanded(child: _buildIconGrid()),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 构建搜索栏
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: AppColors.cardElevation,
        shadowColor: AppColors.cardShadowColor,
        color: AppColors.materialCardColor,
        surfaceTintColor: Colors.transparent,
        shape: AppColors.cardShape,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            decoration: InputDecoration(
              hintText: '搜索天气图标...',
              hintStyle: TextStyle(color: AppColors.textSecondary),
              prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: AppColors.textSecondary),
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              border: InputBorder.none,
            ),
            style: TextStyle(color: AppColors.textPrimary),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ),
      ),
    );
  }

  /// 构建分类选择器
  Widget _buildCategorySelector() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _iconCategories.keys.length,
        itemBuilder: (context, index) {
          final category = _iconCategories.keys.elementAt(index);
          final isSelected = category == _selectedCategory;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = category;
                });
              },
              selectedColor: AppColors.primaryBlue.withOpacity(0.2),
              checkmarkColor: AppColors.primaryBlue,
              labelStyle: TextStyle(
                color: isSelected
                    ? AppColors.primaryBlue
                    : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          );
        },
      ),
    );
  }

  /// 构建图标网格
  Widget _buildIconGrid() {
    final icons = _getFilteredIcons();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.8,
        ),
        itemCount: icons.length,
        itemBuilder: (context, index) {
          final iconInfo = icons[index];
          return _buildIconCard(iconInfo);
        },
      ),
    );
  }

  /// 构建图标卡片
  Widget _buildIconCard(WeatherIconInfo iconInfo) {
    return Card(
      elevation: AppColors.cardElevation,
      shadowColor: AppColors.cardShadowColor,
      color: AppColors.materialCardColor,
      surfaceTintColor: Colors.transparent,
      shape: AppColors.cardShape,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _showIconDetail(iconInfo),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 图标
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: AppColors.backgroundSecondary.withOpacity(0.1),
                ),
                child: Image.asset(
                  iconInfo.assetPath,
                  width: 40,
                  height: 40,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.image_not_supported,
                      color: AppColors.textSecondary,
                      size: 24,
                    );
                  },
                ),
              ),

              const SizedBox(height: 8),

              // 名称
              Text(
                iconInfo.name,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 4),

              // 描述
              Text(
                iconInfo.description,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 获取过滤后的图标列表
  List<WeatherIconInfo> _getFilteredIcons() {
    var icons = _iconCategories[_selectedCategory] ?? [];

    if (_searchQuery.isNotEmpty) {
      icons = icons.where((icon) {
        return icon.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            icon.description.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    return icons;
  }

  /// 显示图标详情
  void _showIconDetail(WeatherIconInfo iconInfo) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.materialCardColor,
        shape: AppColors.cardShape,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 大图标
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: AppColors.backgroundSecondary.withOpacity(0.1),
                ),
                child: Image.asset(
                  iconInfo.assetPath,
                  width: 100,
                  height: 100,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.image_not_supported,
                      color: AppColors.textSecondary,
                      size: 48,
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // 名称
              Text(
                iconInfo.name,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              // 描述
              Text(
                iconInfo.description,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // 关闭按钮
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('关闭'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 显示信息对话框
  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.materialCardColor,
        shape: AppColors.cardShape,
        title: Text(
          '天气图标说明',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '本页面展示了应用中使用的所有天气图标：',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoItem('雨天', '毛毛雨、小雨、中雨、大雨等'),
            _buildInfoItem('雪天', '小雪、大雪等'),
            _buildInfoItem('晴天', '晴、多云、阴天等'),
            _buildInfoItem('其他', '雾、霾、沙尘暴等'),
            const SizedBox(height: 12),
            Text(
              '点击图标可查看大图和详细信息。',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('确定', style: TextStyle(color: AppColors.primaryBlue)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String name, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            '$name: ',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              description,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

/// 天气图标信息类
class WeatherIconInfo {
  final String name;
  final String assetPath;
  final String description;

  WeatherIconInfo(this.name, this.assetPath, this.description);
}
