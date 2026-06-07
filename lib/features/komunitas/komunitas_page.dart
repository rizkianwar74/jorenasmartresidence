import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive_helper.dart';
import '../../core/router/app_router.dart';
import '../../shared/widgets/bottom_nav_bar.dart';
import 'warga_model.dart';
import 'widgets/blok_filter_chips.dart';
import 'widgets/warga_list_item.dart';

class KomunitasPage extends StatefulWidget {
  const KomunitasPage({super.key});

  @override
  State<KomunitasPage> createState() => _KomunitasPageState();
}

class _KomunitasPageState extends State<KomunitasPage> {
  static const double _contentMaxWidth = 600.0;

  static const _filterOptions = ['Semua', 'Blok A', 'Blok B', 'Blok C'];

  String _selectedBlok = 'Blok A';
  String _searchQuery = '';

  List<WargaModel> get _filteredList {
    return mockWargaList.where((w) {
      final matchBlok = _selectedBlok == 'Semua' || w.blok == _selectedBlok;
      final matchSearch = _searchQuery.isEmpty ||
          w.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          w.nomorUnit.contains(_searchQuery);
      return matchBlok && matchSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F7F8),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pushReplacementNamed(context, AppRouter.home),
          child: const Icon(Icons.arrow_back_ios_new, size: 20),
        ),
        title: Text(
          'Warga Residence',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Icon(
                Icons.notifications_outlined,
                color: Colors.black87,
                size: 22,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
              child: Column(
                children: [
                  const SizedBox(height: 12),

                  // --- Search bar ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: TextField(
                        onChanged: (v) => setState(() => _searchQuery = v),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textDark,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Cari warga atau nomor rumah...',
                          hintStyle: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.textGrey,
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: AppColors.textGrey,
                            size: 20,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // --- Filter chips ---
                  BlokFilterChips(
                    options: _filterOptions,
                    selected: _selectedBlok,
                    onSelected: (v) => setState(() => _selectedBlok = v),
                  ),

                  const SizedBox(height: 16),

                  // --- List warga ---
                  Expanded(
                    child: _filteredList.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.search_off_rounded,
                                  size: 48,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Tidak ada warga ditemukan',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: AppColors.textGrey,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(
                              top: 4,
                              bottom: 120,
                            ),
                            itemCount: _filteredList.length,
                            itemBuilder: (_, i) => WargaListItem(
                              warga: _filteredList[i],
                              onTap: () {
                                // TODO: buka profil warga
                              },
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),

          // --- Bottom nav ---
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: BottomNavBar(
              currentIndex: 2,
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