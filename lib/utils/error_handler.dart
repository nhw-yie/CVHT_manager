import 'dart:async';

import 'package:flutter/material.dart';

/// Standard API exception used across the app
class ApiException implements Exception {
  final int? statusCode;
  final String message;
  final Map<String, dynamic>? errors;

  ApiException(this.message, {this.statusCode, this.errors});

  @override
  String toString() => 'ApiException(status=$statusCode, message=$message, errors=$errors)';
}

/// Generic loading state for UI
enum LoadingState { initial, loading, success, error }

/// Centralized error handling helper
class ErrorHandler {
  /// Map error/status codes to friendly messages
  static String mapToMessage(Object error) {
    if (error is ApiException) {
      if (error.statusCode != null) {
        switch (error.statusCode) {
          case 400:
            return error.message.isNotEmpty ? error.message : 'Yêu cầu không hợp lệ.';
          case 401:
            return 'Phiên đã hết hạn. Vui lòng đăng nhập lại.';
          case 403:
            return 'Bạn không có quyền thực hiện hành động này.';
          case 404:
            return 'Không tìm thấy tài nguyên.';
          case 422:
            // collect validation messages
            if (error.errors != null && error.errors!.isNotEmpty) {
              return error.errors!.values.map((v) => v.toString()).join('\n');
            }
            return error.message.isNotEmpty ? error.message : 'Dữ liệu không hợp lệ.';
          case 500:
          default:
            return 'Lỗi máy chủ. Vui lòng thử lại sau.';
        }
      }
      return error.message;
    }

    // Fallback for other exception types
    return error.toString();
  }

  /// Show a snack bar with the mapped message
  static void showSnack(BuildContext context, Object error) {
    final msg = mapToMessage(error);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  /// Optionally show a dialog for critical errors
  static Future<void> showDialogFor(BuildContext context, Object error) async {
    final msg = mapToMessage(error);
    await showDialog<void>(context: context, builder: (ctx) => AlertDialog(title: const Text('Lỗi'), content: Text(msg), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))]));
  }
}

/// A widget that unifies async states for Future/Stream results.
class AsyncValueWidget<T> extends StatelessWidget {
  final Future<T>? future;
  final Stream<T>? stream;
  final Widget Function(BuildContext, T) builder;
  final Widget? loading;
  final Widget Function(BuildContext, Object)? errorBuilder;

  const AsyncValueWidget._({Key? key, this.future, this.stream, required this.builder, this.loading, this.errorBuilder}) : super(key: key);

  factory AsyncValueWidget.future({Key? key, required Future<T> future, required Widget Function(BuildContext, T) builder, Widget? loading, Widget Function(BuildContext, Object)? errorBuilder}) {
    return AsyncValueWidget._(key: key, future: future, builder: builder, loading: loading, errorBuilder: errorBuilder);
  }

  factory AsyncValueWidget.stream({Key? key, required Stream<T> stream, required Widget Function(BuildContext, T) builder, Widget? loading, Widget Function(BuildContext, Object)? errorBuilder}) {
    return AsyncValueWidget._(key: key, stream: stream, builder: builder, loading: loading, errorBuilder: errorBuilder);
  }

  @override
  Widget build(BuildContext context) {
    if (future != null) {
      return FutureBuilder<T>(
        future: future,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) return loading ?? const Center(child: CircularProgressIndicator());
          if (snap.hasError) {
            if (errorBuilder != null) return errorBuilder!(ctx, snap.error!);
            return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text(ErrorHandler.mapToMessage(snap.error!)), const SizedBox(height: 8), ElevatedButton(onPressed: () => {}, child: const Text('Retry'))]));
          }
          if (!snap.hasData) return const SizedBox.shrink();
          return builder(ctx, snap.data as T);
        },
      );
    }

    if (stream != null) {
      return StreamBuilder<T>(
        stream: stream,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) return loading ?? const Center(child: CircularProgressIndicator());
          if (snap.hasError) {
            if (errorBuilder != null) return errorBuilder!(ctx, snap.error!);
            return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text(ErrorHandler.mapToMessage(snap.error!)), const SizedBox(height: 8), ElevatedButton(onPressed: () => {}, child: const Text('Retry'))]));
          }
          if (!snap.hasData) return const SizedBox.shrink();
          return builder(ctx, snap.data as T);
        },
      );
    }

    return const SizedBox.shrink();
  }
}

/// Small widget that displays an error and a retry button wired to a callback.
class RetryWrapper extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;
  final String? label;

  const RetryWrapper({Key? key, required this.error, required this.onRetry, this.label}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final msg = ErrorHandler.mapToMessage(error);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(mainAxisSize: MainAxisSize.min, children: [Text(msg, textAlign: TextAlign.center), const SizedBox(height: 12), ElevatedButton(onPressed: onRetry, child: Text(label ?? 'Thử lại'))]),
      ),
    );
  }
}
