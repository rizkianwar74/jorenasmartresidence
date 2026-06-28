import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../models/security_models.dart';

class SatpamBertugasSection extends StatelessWidget {
  const SatpamBertugasSection({super.key, required this.satpamList});
  final List<SatpamData> satpamList;

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : 'S';
  }

  @override
  Widget build(BuildContext context) {
    final aktifCount = satpamList.where((s) => s.isOnDuty).length;
    // Urutkan: aktif dulu, lalu non-aktif
    final sorted = [...satpamList]
      ..sort((a, b) {
        if (a.isOnDuty == b.isOnDuty) return 0;
        return a.isOnDuty ? -1 : 1;
      });

    return Container(
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
            child: Row(children: [
              Text('Satpam Terdaftar', style: GoogleFonts.inter(
                  fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                    color: aktifCount > 0 ? AppColors.primary : Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(20)),
                child: Text('$aktifCount Aktif', style: GoogleFonts.inter(
                    fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ]),
          ),
          if (satpamList.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
              child: Text('Belum ada satpam terdaftar.',
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.textGrey)),
            )
          else
            ...sorted.map((s) {
              final avatarBg = s.isOnDuty
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : Colors.grey.shade100;
              final avatarText = s.isOnDuty ? AppColors.primary : Colors.grey.shade400;
              final nameColor  = s.isOnDuty ? AppColors.textDark : AppColors.textGrey;
              final dotColor   = s.isOnDuty
                  ? const Color(0xFF16A34A)
                  : Colors.grey.shade300;

              return Container(
                decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.grey.shade100))),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                child: Row(children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: avatarBg,
                    child: Text(_initials(s.nama), style: GoogleFonts.inter(
                        fontSize: 12, fontWeight: FontWeight.bold, color: avatarText)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.nama, style: GoogleFonts.inter(
                          fontSize: 13, fontWeight: FontWeight.w600, color: nameColor)),
                      Text(
                        s.isOnDuty
                            ? (s.lokasi != '-' ? s.lokasi : 'Sedang Bertugas')
                            : 'Tidak Bertugas',
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            color: s.isOnDuty ? AppColors.textGrey : Colors.grey.shade400),
                      ),
                    ],
                  )),
                  Container(width: 8, height: 8,
                      decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
                ]),
              );
            }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
