import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/bottom_nav_bar.dart';
import 'widgets.dart/home_header.dart';
import 'widgets.dart/quick_action_card.dart';
import 'widgets.dart/news_carousel.dart';
import 'widgets.dart/unit_status_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const double _contentMaxWidth = 600.0;

  static const _newsList = [
    NewsItem(
      imageUrl: 'https://picsum.photos/id/1/400/250',
      category: 'Keamanan',
      title: 'Penangkapan Maling di Kompleks',
      date: '12 Okt 2023',
    ),
    NewsItem(
      imageUrl: 'https://picsum.photos/id/200/400/250',
      category: 'Kehilangan',
      title: 'Kucing Pak Owi Hilang',
      date: '14 Okt 2023',
    ),
    NewsItem(
      imageUrl: 'https://picsum.photos/id/58/400/250',
      category: 'Keamanan',
      title: 'Protokol Keamanan Baru',
      date: '15 Okt 2023',
    ),
  ];

  @override
  Widget build(BuildContext context) {
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

                    HomeHeader(
                      userName: 'Budi',
                      greeting: 'Selamat Pagi',
                      notificationCount: 3,
                      onNotificationTap: () {
                        // TODO: navigasi ke halaman notifikasi
                      },
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 6,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: QuickActionCard(
                              icon: Icons.account_balance_wallet_outlined,
                              iconColor: AppColors.primary,
                              bgIconColor: AppColors.primary.withOpacity(0.1),
                              title: 'Bayar Tagihan',
                              subtitle: '3 TAGIHAN AKTIF',
                              onTap: () {
                                // TODO: navigasi ke halaman tagihan
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
                                // TODO: trigger panggil satpam
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    NewsCarousel(
                      items: _newsList,
                      onSeeAllTap: () {
                        // TODO: navigasi ke semua berita
                      },
                      onNewsTap: (item) {
                        // TODO: navigasi ke detail berita
                      },
                    ),

                    UnitStatusCard(
                      blockName: 'Blok A',
                      unitNumber: '42',
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