import 'dart:convert';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Gambar foto bantuan — aware base64 (data URI) maupun URL http biasa.
// Disamakan dengan pola ProfileAvatar: base64 dipakai untuk foto baru (lihat
// BantuanRepository.sendRequest), tapi tetap dukung URL http kalau ada data
// lama yang sempat tersimpan lewat Firebase Storage sebelumnya.
// ─────────────────────────────────────────────────────────────────────────────

class BantuanFotoImage extends StatelessWidget {
  const BantuanFotoImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.dark = false,
  });
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final bool dark;

  bool get _isBase64 => url.startsWith('data:image');

  @override
  Widget build(BuildContext context) {
    if (_isBase64) {
      try {
        final bytes = base64Decode(url.split(',').last);
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => _placeholder(),
        );
      } catch (_) {
        return _placeholder();
      }
    }
    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return _loading();
      },
      errorBuilder: (_, __, ___) => _placeholder(),
    );
  }

  Widget _loading() => Container(
        width: width,
        height: height,
        color: dark ? Colors.black : const Color(0xFFF5F5F5),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: dark ? Colors.white : null,
            ),
          ),
        ),
      );

  Widget _placeholder() => Container(
        width: width,
        height: height,
        color: dark ? Colors.black : const Color(0xFFF5F5F5),
        child: Icon(Icons.broken_image_outlined,
            color: dark ? Colors.white54 : Colors.grey.shade400,
            size: dark ? 48 : 24),
      );
}
