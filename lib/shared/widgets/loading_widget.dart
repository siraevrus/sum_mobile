import 'package:flutter/material.dart';
import 'package:sum_warehouse/core/theme/app_colors.dart';

/// Виджет загрузки с индикатором
class LoadingWidget extends StatelessWidget {
  final String? message;
  final double? size;
  
  const LoadingWidget({
    super.key,
    this.message,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: size ?? 40,
            height: size ?? 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Виджет ошибки с возможностью повторить
class AppErrorWidget extends StatelessWidget {
  final dynamic error;
  final VoidCallback? onRetry;
  final String? retryButtonText;
  final String? customMessage;
  
  const AppErrorWidget({
    super.key,
    required this.error,
    this.onRetry,
    this.retryButtonText,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    final errorMessage = _getErrorMessage();
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getErrorIcon(),
              size: 64,
              color: _getErrorColor(),
            ),
            const SizedBox(height: 16),
            Text(
              _getErrorTitle(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: _getErrorColor(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(retryButtonText ?? 'Повторить'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getErrorMessage() {
    if (customMessage != null) return customMessage!;
    
    // Проверяем строковые ошибки на наличие сетевых проблем
    if (error is String) {
      final errorString = error as String;
      if (errorString.contains('NetworkException') ||
          errorString.contains('подключения к сети') ||
          errorString.contains('время ожидания') ||
          errorString.contains('подключение') ||
          errorString.contains('интернет') ||
          errorString.contains('сеть')) {
        return 'Отсутствует подключение к интернету, пожалуйста подождите';
      }
    }
    
    return error?.toString() ?? 'Произошла неизвестная ошибка';
  }

  String _getErrorTitle() {
    if (error is String) {
      final errorString = error as String;
      if (errorString.contains('NetworkException') ||
          errorString.contains('подключение') ||
          errorString.contains('интернет') ||
          errorString.contains('сеть')) {
        return 'Нет соединения';
      }
    }
    return 'Ошибка загрузки';
  }

  IconData _getErrorIcon() {
    if (error is String) {
      final errorString = error as String;
      if (errorString.contains('NetworkException') ||
          errorString.contains('подключение') ||
          errorString.contains('интернет') ||
          errorString.contains('сеть')) {
        return Icons.wifi_off;
      }
    }
    return Icons.error_outline;
  }

  Color _getErrorColor() {
    if (error is String) {
      final errorString = error as String;
      if (errorString.contains('NetworkException') ||
          errorString.contains('подключение') ||
          errorString.contains('интернет') ||
          errorString.contains('сеть')) {
        return Colors.orange;
      }
    }
    return AppColors.error;
  }
}

/// Виджет пустого состояния
class EmptyWidget extends StatelessWidget {
  final String message;
  final IconData? icon;
  final Widget? action;
  
  const EmptyWidget({
    super.key,
    required this.message,
    this.icon,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon ?? Icons.inbox,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Индикатор загрузки в виде скелетона
class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  
  const SkeletonLoader({
    super.key,
    this.width = double.infinity,
    this.height = 20,
    this.borderRadius,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: -1, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(4),
            gradient: LinearGradient(
              colors: [
                Colors.grey[300]!,
                Colors.grey[100]!,
                Colors.grey[300]!,
              ],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ].map((e) => e.clamp(0.0, 1.0)).toList(),
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        );
      },
    );
  }
}
