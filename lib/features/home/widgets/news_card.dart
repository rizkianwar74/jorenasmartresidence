import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

class NewsCard extends StatelessWidget {
  const NewsCard({
    super.key,
    required this.imageUrl,
    required this.category,
    required this.title,
    required this.date,
    this.onTap,
  });

  final String imageUrl;
  final String category;
  final String title;
  final String date;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double cardWidth = screenWidth < 600 ? screenWidth * 0.75 : 280.0;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: cardWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 175,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade200,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _BeritaImage(
                      imageUrl: imageUrl,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        color: Colors.white.withValues(alpha: 0.9),
                        child: Text(
                          category,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 12,
                        color: AppColors.textGrey,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        date,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helper: tampilkan gambar dari URL biasa atau base64 data URL ──────────────
//
// Dibuat StatefulWidget supaya base64 hanya di-decode SEKALI (di initState),
// bukan setiap kali parent rebuild. Tanpa ini gambar blink tiap setState
// di home_page (feed stream, bantuan listener, dll.).
// gaplessPlayback: true mencegah blank frame saat widget di-rebuild.

class _BeritaImage extends StatefulWidget {
  const _BeritaImage({
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  State<_BeritaImage> createState() => _BeritaImageState();
}

class _BeritaImageState extends State<_BeritaImage> {
  Uint8List? _bytes;
  bool _isBase64 = false;

  @override
  void initState() {
    super.initState();
    _decode(widget.imageUrl);
  }

  @override
  void didUpdateWidget(_BeritaImage oldWidget) {
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

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrl.isEmpty) return _placeholder();

    // Base64 — bytes sudah di-decode saat initState, tidak decode ulang
    if (_isBase64) {
      if (_bytes == null) return _placeholder();
      return Image.memory(
        _bytes!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        gaplessPlayback: true, // tidak blank saat parent rebuild
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }

    // URL biasa (https://)
    return Image.network(
      widget.imageUrl,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      gaplessPlayback: true, // tidak blank saat parent rebuild
      errorBuilder: (_, __, ___) => _placeholder(),
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return Container(
          color: Colors.grey.shade100,
          child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2)),
        );
      },
    );
  }
}