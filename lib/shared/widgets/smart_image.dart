import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

/// Widget gambar yang transparan terhadap sumber — base64 data URI atau URL.
///
/// ## Kenapa StatefulWidget?
/// base64 hanya di-decode SEKALI di [initState] / [didUpdateWidget].
/// Kalau decode dilakukan di [build], gambar blink setiap kali parent
/// melakukan setState (misalnya stream Firestore atau bantuan listener).
/// [gaplessPlayback: true] mencegah blank frame saat widget di-rebuild.
///
/// ## Penggunaan
/// ```dart
/// // Sebagai widget gambar biasa
/// SmartImage(
///   imageUrl: doc.foto,   // bisa 'data:image/jpeg;base64,...' atau 'https://...'
///   width: 80,
///   height: 80,
///   fit: BoxFit.cover,
/// )
///
/// // Sebagai ImageProvider untuk CircleAvatar / DecorationImage
/// CircleAvatar(
///   backgroundImage: SmartImage.provider(user.photoUrl),
///   radius: 24,
/// )
/// ```
class SmartImage extends StatefulWidget {
  const SmartImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;

  /// Radius untuk sudut membulat — opsional.
  final BorderRadius? borderRadius;

  // ── Static helper: kembalikan ImageProvider (bukan widget) ───────────────
  /// Dipakai dengan [CircleAvatar.backgroundImage] atau [DecorationImage].
  /// Kembalikan `null` jika [imageUrl] kosong / null / gagal decode.
  static ImageProvider? provider(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return null;
    if (imageUrl.startsWith('data:')) {
      try {
        return MemoryImage(base64Decode(imageUrl.split(',').last));
      } catch (_) {
        return null;
      }
    }
    return NetworkImage(imageUrl);
  }

  @override
  State<SmartImage> createState() => _SmartImageState();
}

class _SmartImageState extends State<SmartImage> {
  Uint8List? _bytes;
  bool _isBase64 = false;

  @override
  void initState() {
    super.initState();
    _decode(widget.imageUrl);
  }

  @override
  void didUpdateWidget(SmartImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _decode(widget.imageUrl);
    }
  }

  void _decode(String url) {
    if (url.startsWith('data:')) {
      _isBase64 = true;
      try {
        _bytes = base64Decode(url.split(',').last);
      } catch (_) {
        _bytes = null;
      }
    } else {
      _isBase64 = false;
      _bytes = null;
    }
  }

  static Widget _placeholder() => Container(
        color: Colors.grey.shade200,
        child: const Center(
          child: Icon(Icons.image_outlined, color: Colors.grey, size: 36),
        ),
      );

  Widget _buildImage() {
    if (widget.imageUrl.isEmpty) return _placeholder();

    if (_isBase64) {
      if (_bytes == null) return _placeholder();
      return Image.memory(
        _bytes!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }

    return Image.network(
      widget.imageUrl,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => _placeholder(),
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return Container(
          color: Colors.grey.shade100,
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final img = _buildImage();
    if (widget.borderRadius == null) return img;
    return ClipRRect(borderRadius: widget.borderRadius!, child: img);
  }
}
