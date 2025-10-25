import 'package:flutter/material.dart';
import '../utils/error_handler.dart';
import '../constants/app_colors.dart';

/// 用户友好的错误提示对话框
class ErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final AppErrorType errorType;
  final VoidCallback? onRetry;
  final String? retryText;

  const ErrorDialog({
    super.key,
    required this.title,
    required this.message,
    required this.errorType,
    this.onRetry,
    this.retryText,
  });

  /// 显示错误对话框
  static Future<void> show({
    required BuildContext context,
    required String title,
    required String message,
    required AppErrorType errorType,
    VoidCallback? onRetry,
    String? retryText,
  }) {
    return showDialog(
      context: context,
      builder: (context) => ErrorDialog(
        title: title,
        message: message,
        errorType: errorType,
        onRetry: onRetry,
        retryText: retryText,
      ),
    );
  }

  /// 显示网络错误对话框
  static Future<void> showNetworkError({
    required BuildContext context,
    String? message,
    VoidCallback? onRetry,
  }) {
    return show(
      context: context,
      title: '网络连接异常',
      message:
          message ??
          ErrorHandler.getUserFriendlyMessage(AppErrorType.network, ''),
      errorType: AppErrorType.network,
      onRetry: onRetry,
      retryText: '重试',
    );
  }

  /// 显示定位错误对话框
  static Future<void> showLocationError({
    required BuildContext context,
    String? message,
    VoidCallback? onRetry,
  }) {
    return show(
      context: context,
      title: '定位服务异常',
      message:
          message ??
          ErrorHandler.getUserFriendlyMessage(AppErrorType.location, ''),
      errorType: AppErrorType.location,
      onRetry: onRetry,
      retryText: '重新定位',
    );
  }

  /// 显示权限错误对话框
  static Future<void> showPermissionError({
    required BuildContext context,
    String? message,
  }) {
    return show(
      context: context,
      title: '权限不足',
      message:
          message ??
          ErrorHandler.getUserFriendlyMessage(AppErrorType.permission, ''),
      errorType: AppErrorType.permission,
      retryText: null, // 权限错误不提供重试按钮
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.materialCardColor,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Row(
        children: [
          Icon(_getErrorIcon(), color: _getErrorColor(), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        message,
        style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
      ),
      actions: [
        if (onRetry != null)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onRetry!();
            },
            child: Text(
              retryText ?? '重试',
              style: TextStyle(
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            '确定',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  IconData _getErrorIcon() {
    switch (errorType) {
      case AppErrorType.network:
        return Icons.wifi_off;
      case AppErrorType.location:
        return Icons.location_off;
      case AppErrorType.permission:
        return Icons.lock;
      case AppErrorType.dataParsing:
        return Icons.error_outline;
      case AppErrorType.cache:
        return Icons.cached;
      default:
        return Icons.error_outline;
    }
  }

  Color _getErrorColor() {
    switch (errorType) {
      case AppErrorType.network:
        return AppColors.warning;
      case AppErrorType.location:
        return AppColors.warning;
      case AppErrorType.permission:
        return AppColors.error;
      case AppErrorType.dataParsing:
        return AppColors.warning;
      case AppErrorType.cache:
        return AppColors.warning;
      default:
        return AppColors.error;
    }
  }
}

/// 错误提示Toast
class ErrorToast {
  /// 显示错误Toast
  static void show({
    required BuildContext context,
    required String message,
    AppErrorType? errorType,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              errorType != null
                  ? _getErrorIcon(errorType)
                  : Icons.error_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
        backgroundColor: errorType != null
            ? _getErrorColor(errorType)
            : Colors.grey[700],
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  static IconData _getErrorIcon(AppErrorType errorType) {
    switch (errorType) {
      case AppErrorType.network:
        return Icons.wifi_off;
      case AppErrorType.location:
        return Icons.location_off;
      case AppErrorType.permission:
        return Icons.lock;
      case AppErrorType.dataParsing:
        return Icons.error_outline;
      case AppErrorType.cache:
        return Icons.cached;
      default:
        return Icons.error_outline;
    }
  }

  static Color _getErrorColor(AppErrorType errorType) {
    switch (errorType) {
      case AppErrorType.network:
        return Colors.orange;
      case AppErrorType.location:
        return Colors.orange;
      case AppErrorType.permission:
        return Colors.red;
      case AppErrorType.dataParsing:
        return Colors.orange;
      case AppErrorType.cache:
        return Colors.orange;
      default:
        return Colors.red;
    }
  }
}
