import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'bantuan_foto_image.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Viewer foto fullscreen (swipe antar foto kalau lebih dari satu)
// ─────────────────────────────────────────────────────────────────────────────

class BantuanFotoViewer extends StatefulWidget {
  const BantuanFotoViewer({super.key, required this.urls, required this.initialIndex});
  final List<String> urls;
  final int initialIndex;

  @override
  State<BantuanFotoViewer> createState() => _BantuanFotoViewerState();
}

class _BantuanFotoViewerState extends State<BantuanFotoViewer> {
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
            child: BantuanFotoImage(
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
