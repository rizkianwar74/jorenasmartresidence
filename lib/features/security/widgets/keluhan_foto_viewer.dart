import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FullscreenFotoViewer extends StatefulWidget {
  const FullscreenFotoViewer({
    super.key,
    required this.urls,
    required this.initialIndex,
  });
  final List<String> urls;
  final int initialIndex;

  @override
  State<FullscreenFotoViewer> createState() => _FullscreenFotoViewerState();
}

class _FullscreenFotoViewerState extends State<FullscreenFotoViewer> {
  late final PageController _pageController;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _pageController = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${_index + 1} / ${widget.urls.length}',
          style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
        ),
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.urls.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (_, i) => InteractiveViewer(
          minScale: 1,
          maxScale: 4,
          child: Center(
            child: KeluhanFotoImage(
              url: widget.urls[i],
              fit: BoxFit.contain,
              dark: true,
            ),
          ),
        ),
      ),
    );
  }
}

class KeluhanFotoImage extends StatelessWidget {
  const KeluhanFotoImage({
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
