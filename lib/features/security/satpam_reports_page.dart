import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/satpam_bottom_nav.dart';
import 'widgets/keluhan_tab.dart';
import 'widgets/lapor_insiden_tab.dart';

class SatpamReportsPage extends StatefulWidget {
  const SatpamReportsPage({super.key});

  @override
  State<SatpamReportsPage> createState() => _SatpamReportsPageState();
}

class _SatpamReportsPageState extends State<SatpamReportsPage>
    with SingleTickerProviderStateMixin {
  static const double _contentMaxWidth = 600.0;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F9),
        body: Stack(
          children: [
            Center(
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: _contentMaxWidth),
                child: Column(
                  children: [
                    // ── Top Bar ──────────────────────────────────────────
                    const _TopBar(),

                    // ── Tab Bar ──────────────────────────────────────────
                    Container(
                      color: Colors.white,
                      child: TabBar(
                        controller: _tabController,
                        labelColor: AppColors.primary,
                        unselectedLabelColor: const Color(0xFF94A3B8),
                        indicatorColor: AppColors.primary,
                        indicatorWeight: 2.5,
                        labelStyle: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                        unselectedLabelStyle: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        tabs: const [
                          Tab(text: 'Keluhan Warga'),
                          Tab(text: 'Lapor Insiden'),
                        ],
                      ),
                    ),

                    // ── Tab Views ─────────────────────────────────────────
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: const [
                          KeluhanTab(),
                          LaporInsidenTab(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Bottom Nav ────────────────────────────────────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SatpamBottomNav(currentIndex: 2),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 20,
        right: 20,
        bottom: 12,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 20, color: Color(0xFF0D1B2A)),
          ),
          const SizedBox(width: 12),
          Icon(Icons.security, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Text(
            'Laporan & Keluhan',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const Spacer(),
          const Icon(Icons.notifications_outlined,
              size: 22, color: Color(0xFF0D1B2A)),
          const SizedBox(width: 14),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Icon(Icons.person_outline,
                size: 18, color: Color(0xFF0D1B2A)),
          ),
        ],
      ),
    );
  }
}
