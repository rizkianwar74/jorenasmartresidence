import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/bottom_nav_bar.dart';
import '../../core/router/app_router.dart';
import '../../core/data/berita_data.dart';
import '../auth/auth_repository.dart';
import '../berita/berita_detail_page.dart';
import '../berita/berita_list_page.dart';
import 'widgets/home_header.dart';
import 'widgets/quick_action_card.dart';
import 'widgets/news_carousel.dart';
import 'widgets/unit_status_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const double _contentMaxWidth = 600.0;
  static const bool _sudahLunas = false;

  // Data berita dari berita_data.dart
  static final _beritaList = getBeritaTerbaru(limit: 3);
  static final _newsList = _beritaList
      .map((b) => NewsItem(
            imageUrl: b.imageUrl,
            category: b.kategoriLabel,
            title: b.judul,
            date: b.tanggal,
          ))
      .toList();

  // Ambil greeting berdasarkan jam
  String _buildGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  @override
  Widget build(BuildContext context) {
    // Ambil data dari AuthRepository — sudah diisi saat login
    final user = AuthRepository.currentUser;
    final namaDepan = user?.namaLengkap.split(' ').first ?? 'Pengguna';
    final namaLengkap = user?.namaLengkap ?? 'Pengguna';
    final blok = user?.blok ?? '-';
    final nomorUnit = user?.nomorUnit ?? '-';

    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: MediaQuery.of(context).padding.top),

                    // Header — nama dari database
                    HomeHeader(
                      userName: namaDepan,
                      greeting: _buildGreeting(),
                      notificationCount: 3,
                      onNotificationTap: () {},
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 6,
                      ),
                      child: Row(
                        children: [
                          // Kartu tagihan — nama dari database
                          Expanded(
                            child: TagihanCard(
                              namaPenghuni: namaLengkap,
                              jumlahTagihan: 'Rp 450.000',
                              sudahLunas: _sudahLunas,
                              onBayarTap: () {
                                Navigator.pushNamed(
                                  context,
                                  AppRouter.tagihan,
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: QuickActionCard(
                              icon: Icons.security,
                              iconColor: Colors.red,
                              bgIconColor: Colors.red.shade50,
                              title: 'Panggil Satpam',
                              subtitle: 'RESPON CEPAT',
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  AppRouter.security,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    NewsCarousel(
                      items: _newsList,
                      onSeeAllTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BeritaListPage(),
                          ),
                        );
                      },
                      onNewsTap: (item) {
                        final index = _newsList.indexOf(item);
                        if (index != -1) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BeritaDetailPage(
                                berita: _beritaList[index],
                              ),
                            ),
                          );
                        }
                      },
                    ),

                    // Unit status — blok & unit dari database
                    UnitStatusCard(
                      blockName: blok,
                      unitNumber: nomorUnit,
                      paymentStatus: PaymentStatus.paid,
                    ),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: BottomNavBar(
              currentIndex: 0,
              contentMaxWidth: _contentMaxWidth,
            ),
          ),

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
}
