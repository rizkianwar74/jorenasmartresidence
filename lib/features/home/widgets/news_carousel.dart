import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import 'news_card.dart';

class NewsItem {
  const NewsItem({
    required this.imageUrl,
    required this.category,
    required this.title,
    required this.date,
  });

  final String imageUrl;
  final String category;
  final String title;
  final String date;
}

class NewsCarousel extends StatelessWidget {
  const NewsCarousel({
    super.key,
    required this.items,
    this.onSeeAllTap,
    this.onNewsTap,
  });

  final List<NewsItem> items;
  final VoidCallback? onSeeAllTap;
  final ValueChanged<NewsItem>? onNewsTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
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
                  color: AppColors.textDark,
                ),
              ),
              GestureDetector(
                onTap: onSeeAllTap,
                child: Text(
                  'Lihat Semua',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Carousel
        SizedBox(
          height: 240,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final item = items[index];
              return NewsCard(
                imageUrl: item.imageUrl,
                category: item.category,
                title: item.title,
                date: item.date,
                onTap: () => onNewsTap?.call(item),
              );
            },
          ),
        ),
      ],
    );
  }
}