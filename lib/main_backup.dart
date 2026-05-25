import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const SmartResidenceApp());
}

class SmartResidenceApp extends StatelessWidget {
  const SmartResidenceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Residence',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF6F7F8),
        primaryColor: const Color(0xFF1173D4),
        textTheme: GoogleFonts.interTextTheme(
          Theme.of(context).textTheme,
        ),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xFF1173D4);
    final Color textDark = const Color(0xFF0D141B);
    final Color textGrey = const Color(0xFF94A3B8);
    
    // Mendapatkan lebar layar saat ini
    double screenWidth = MediaQuery.of(context).size.width;
    // Tentukan lebar maksimum konten agar tidak melar di Desktop
    double contentMaxWidth = 600.0; 

    return Scaffold(
      body: Stack(
        children: [
          // --- Main Content Scrollable ---
          // Center & ConstrainedBox membuat tampilan rapi di tengah pada layar Desktop
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: contentMaxWidth),
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 120), // Spacer lebih besar untuk Nav
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: MediaQuery.of(context).padding.top),

                    // --- Header ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SMART RESIDENCE',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: primaryColor,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Selamat Pagi, Kontol',
                                style: GoogleFonts.inter(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: textDark,
                                ),
                              ),
                            ],
                          ),
                          // Notification Button
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey.shade200),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 2,
                                  offset: const Offset(0, 1),
                                )
                              ],
                            ),
                            child: Stack(
                              children: [
                                const Center(
                                  child: Icon(Icons.notifications_outlined, color: Colors.black87),
                                ),
                                Positioned(
                                  top: 12,
                                  right: 12,
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // --- Quick Action Buttons ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildQuickActionCard(
                              icon: Icons.account_balance_wallet_outlined,
                              iconColor: primaryColor,
                              bgIconColor: primaryColor.withOpacity(0.1),
                              title: 'Bayar Tagihan',
                              subtitle: '3 TAGIHAN AKTIF',
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildQuickActionCard(
                              icon: Icons.security,
                              iconColor: Colors.red,
                              bgIconColor: Colors.red.shade50,
                              title: 'Panggil Satpam',
                              subtitle: 'RESPON CEPAT',
                            ),
                          ),
                        ],
                      ),
                    ),

                    // --- Section Header: Berita ---
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Berita Komunitas',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textDark,
                            ),
                          ),
                          Text(
                            'Lihat Semua',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // --- Carousel Berita ---
                    SizedBox(
                      height: 240,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        physics: const BouncingScrollPhysics(),
                        children: [
                          // Card width dinamis: Di HP 80% layar, di Desktop tetap 280px
                          _buildNewsCard(
                            context,
                            imageUrl: 'https://cdns.klimg.com/mav-prod-resized/1280x720/ori/image_bank/2024/12/01/165223.910-profil-bahlil-lahadalia-menteri-esdm-yang-disorot-terkait-larangan-ojol-pakai-pertalite-1.jpg',
                            category: 'Keamanan',
                            title: 'Penangkapan Maling di kompleks',
                            date: '12 Okt 2023',
                          ),
                          const SizedBox(width: 16),
                          _buildNewsCard(
                            context,
                            imageUrl: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSUVMrz9CLPzh3xLOajKg5gw7WLJUFAcdzK3w&s',
                            category: 'Kehilangan',
                            title: 'Kucing Pak Owi Hilang',
                            date: '14 Okt 2023',
                          ),
                          const SizedBox(width: 16),
                          _buildNewsCard(
                            context,
                            imageUrl: 'https://picsum.photos/id/58/400/250',
                            category: 'KEAMANAN',
                            title: 'Protokol Keamanan Baru',
                            date: '15 Okt 2023',
                          ),
                        ],
                      ),
                    ),

                    // --- Quick Summary Section ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade50),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Wrap dengan Expanded agar text tidak overflow di layar kecil
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: primaryColor.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.apartment, color: primaryColor),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Status Unit',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: textGrey,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          'Blok A - No. 42',
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            color: textDark,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Iuran Bulan Ini',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: textGrey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  'Terbayar',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: Colors.green.shade600,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // --- Bottom Navigation Bar ---
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  // Menggunakan Center & ConstrainedBox pada konten Nav Bar
                  // Agar icon tidak menyebar terlalu jauh di Desktop
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: contentMaxWidth),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildNavItem(Icons.home_filled, 'Home', true),
                          _buildNavItem(Icons.grid_view, 'Layanan', false),
                          _buildNavItem(Icons.groups, 'Komunitas', false),
                          _buildNavItem(Icons.person, 'Profil', false),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Home Indicator
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 130,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Widget Builders ---

  Widget _buildQuickActionCard({
    required IconData icon,
    required Color iconColor,
    required Color bgIconColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      height: 144, 
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade50),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: bgIconColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0D141B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF94A3B8),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildNewsCard(
    BuildContext context, {
    required String imageUrl,
    required String category,
    required String title,
    required String date,
  }) {
    // Logika Responsive Lebar Kartu:
    // Jika layar < 600px (HP), lebar kartu = 75% lebar layar.
    // Jika layar > 600px (Tablet/Desktop), lebar kartu tetap 280px.
    double screenWidth = MediaQuery.of(context).size.width;
    double cardWidth = screenWidth < 600 ? screenWidth * 0.75 : 280.0;

    return SizedBox(
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
                  image: DecorationImage(
                    image: NetworkImage(imageUrl),
                    fit: BoxFit.cover,
                  ),
                  color: Colors.grey.shade200,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      color: Colors.white.withOpacity(0.9),
                      child: Text(
                        category,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1173D4),
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
                    color: const Color(0xFF0D141B),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 12, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 6),
                    Text(
                      date,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive) {
    final color = isActive ? const Color(0xFF1173D4) : const Color(0xFF94A3B8);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 26),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            color: color,
            letterSpacing: -0.2,
          ),
        )
      ],
    );
  }
}