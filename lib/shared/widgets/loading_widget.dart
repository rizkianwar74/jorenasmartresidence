import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Loading indicator inline — dipakai di dalam konten (bukan full-screen).
///
/// ```dart
/// // Tampilkan di tengah area
/// const LoadingWidget()
///
/// // Dengan tinggi tetap (untuk list / card placeholder)
/// LoadingWidget(height: 200)
/// ```
class LoadingWidget extends StatelessWidget {
  const LoadingWidget({
    super.key,
    this.height,
    this.color,
    this.strokeWidth = 2.5,
  });

  final double? height;
  final Color? color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final indicator = CircularProgressIndicator(
      strokeWidth: strokeWidth,
      color: color ?? AppColors.primary,
    );

    if (height != null) {
      return SizedBox(
        height: height,
        child: Center(child: indicator),
      );
    }
    return Center(child: indicator);
  }
}
