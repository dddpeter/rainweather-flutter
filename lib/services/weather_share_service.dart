import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:gal/gal.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/weather_model.dart';
import '../models/location_model.dart';
import '../models/sun_moon_index_model.dart';
import '../providers/theme_provider.dart';
import '../widgets/weather_poster_widget.dart';

/// 天气分享服务
/// 负责生成天气海报并保存到相册
class WeatherShareService {
  static final WeatherShareService instance = WeatherShareService._internal();

  factory WeatherShareService() {
    return instance;
  }

  WeatherShareService._internal();

  final ScreenshotController _screenshotController = ScreenshotController();

  /// 生成并预览天气海报（先预览，再保存）
  ///
  /// [context] - BuildContext
  /// [weather] - 天气数据
  /// [location] - 位置信息
  /// [themeProvider] - 主题提供者
  /// [sunMoonIndexData] - 日出日落和生活指数数据（可选）
  ///
  /// 返回：成功返回 true，失败返回 false
  Future<bool> generateAndSavePoster({
    required BuildContext context,
    required WeatherModel weather,
    required LocationModel location,
    required ThemeProvider themeProvider,
    SunMoonIndexData? sunMoonIndexData,
  }) async {
    // 先显示预览对话框
    return await _showPreviewDialog(
      context: context,
      weather: weather,
      location: location,
      themeProvider: themeProvider,
      sunMoonIndexData: sunMoonIndexData,
    );
  }

  /// 显示预览对话框
  Future<bool> _showPreviewDialog({
    required BuildContext context,
    required WeatherModel weather,
    required LocationModel location,
    required ThemeProvider themeProvider,
    SunMoonIndexData? sunMoonIndexData,
  }) async {
    if (!context.mounted) return false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.9), // 黑色半透明遮罩
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.98,
            maxWidth: 375,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 海报预览（可滚动）
              Flexible(
                child: SingleChildScrollView(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: WeatherPosterWidget(
                      weather: weather,
                      location: location,
                      themeProvider: themeProvider,
                      sunMoonIndexData: sunMoonIndexData,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12), // 减小按钮区域间距
              // 操作按钮
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 取消按钮
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        icon: const Icon(Icons.close, size: 20),
                        label: const Text('取消'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.9),
                          foregroundColor: const Color(0xFF012d78),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // 保存按钮
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.of(dialogContext).pop(true);
                        },
                        icon: const Icon(Icons.save_alt, size: 20),
                        label: const Text('保存到相册'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // 如果用户点击了保存，执行保存逻辑
    if (result == true && context.mounted) {
      return await _saveToGallery(
        context: context,
        weather: weather,
        location: location,
        themeProvider: themeProvider,
        sunMoonIndexData: sunMoonIndexData,
      );
    }

    return false;
  }

  /// 实际保存到相册的逻辑
  Future<bool> _saveToGallery({
    required BuildContext context,
    required WeatherModel weather,
    required LocationModel location,
    required ThemeProvider themeProvider,
    SunMoonIndexData? sunMoonIndexData,
  }) async {
    try {
      // 1. 请求存储权限
      final hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        // 延迟显示消息，等待对话框完全关闭
        await Future.delayed(const Duration(milliseconds: 300));
        if (context.mounted) {
          _showMessage(context, '需要存储权限才能保存图片到相册');
        }
        return false;
      }

      // 2. 显示加载提示（延迟显示，等待对话框关闭）
      await Future.delayed(const Duration(milliseconds: 300));
      if (context.mounted) {
        _showLoadingMessage(context, '正在生成天气海报...');
      }

      // 3. 生成海报
      final Uint8List? imageBytes = await _screenshotController
          .captureFromWidget(
            WeatherPosterWidget(
              weather: weather,
              location: location,
              themeProvider: themeProvider,
              sunMoonIndexData: sunMoonIndexData,
            ),
            delay: const Duration(milliseconds: 100),
            context: context,
            pixelRatio: 2.0, // 高清图片
          );

      if (imageBytes == null) {
        if (context.mounted) {
          _showMessage(context, '生成海报失败');
        }
        return false;
      }

      // 4. 保存到相册
      try {
        await Gal.putImageBytes(
          imageBytes,
          name: 'weather_${DateTime.now().millisecondsSinceEpoch}',
        );

        // 5. 保存成功
        if (context.mounted) {
          _showSuccessMessage(context, '天气海报已保存到相册');
        }
        return true;
      } catch (galError) {
        debugPrint('❌ Gal: 保存到相册失败 - $galError');
        if (context.mounted) {
          _showMessage(context, '保存到相册失败');
        }
        return false;
      }
    } catch (e) {
      debugPrint('❌ WeatherShareService: 生成或保存海报失败 - $e');
      if (context.mounted) {
        _showMessage(context, '生成天气海报失败：${e.toString()}');
      }
      return false;
    }
  }

  /// 请求存储权限
  Future<bool> _requestStoragePermission() async {
    // Android 13 及以上使用新的照片权限
    if (await Permission.photos.isGranted) {
      return true;
    }

    // Android 12 及以下使用存储权限
    if (await Permission.storage.isGranted) {
      return true;
    }

    // 请求权限
    Map<Permission, PermissionStatus> statuses = await [
      Permission.photos,
      Permission.storage,
    ].request();

    // 检查任一权限是否被授予
    return statuses[Permission.photos]?.isGranted == true ||
        statuses[Permission.storage]?.isGranted == true;
  }

  /// 显示加载消息
  void _showLoadingMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 16),
            Text(message),
          ],
        ),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// 显示提示消息
  void _showMessage(BuildContext context, String message, {int duration = 2}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: duration),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// 显示成功消息
  void _showSuccessMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFF4CAF50),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
