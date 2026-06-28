import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'reports_shared_widgets.dart';

class FotoFullscreen extends StatefulWidget {
  const FotoFullscreen({
    super.key,
    required this.urls,
    required this.initialIndex,
  });
  final List<String> urls;
  final int initialIndex;

  @override
  State<FotoFullscreen> createState() => _FotoFullscreenState();
}

class _FotoFullscreenState extends State<FotoFullscreen> {
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Close + counter
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (widget.urls.length > 1)
                Text(
                  '${_current + 1} / ${widget.urls.length}',
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                )
              else
                const SizedBox(),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: ReportFotoImage(
              url: widget.urls[_current],
              fit: BoxFit.contain,
              dark: true,
            ),
          ),

          // Prev / Next
          if (widget.urls.length > 1) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                NavBtn(
                  icon: Icons.arrow_back_ios_new,
                  enabled: _current > 0,
                  onTap: () => setState(() => _current--),
                ),
                const SizedBox(width: 16),
                NavBtn(
                  icon: Icons.arrow_forward_ios,
                  enabled: _current < widget.urls.length - 1,
                  onTap: () => setState(() => _current++),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class NavBtn extends StatelessWidget {
  const NavBtn({
    super.key,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: enabled ? Colors.white24 : Colors.white10,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon,
            color: enabled ? Colors.white : Colors.white38, size: 18),
      ),
    );
  }
}
