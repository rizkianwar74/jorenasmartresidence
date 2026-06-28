import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../pembayaran/models/tagihan_model.dart';
import '../models/tx_group.dart';
import 'payment_detail_shared_widgets.dart';

class SummaryHeaderCard extends StatelessWidget {
  const SummaryHeaderCard({
    super.key,
    required this.namaResiden,
    required this.blok,
    required this.nomorUnit,
    this.nomorHp,
    required this.allTagihan,
    required this.latestG,
  });
  final String namaResiden;
  final String blok;
  final String nomorUnit;
  final String? nomorHp;
  final List<TagihanModel> allTagihan;
  final TxGroup? latestG;

  @override
  Widget build(BuildContext context) {
    final initials = namaResiden.isNotEmpty
        ? namaResiden.trim().split(' ').take(2).map((w) => w[0].toUpperCase()).join()
        : '?';

    final totalDibayar = allTagihan
        .where((t) => t.status == StatusTagihan.lunas)
        .fold(0, (s, t) => s + t.jumlah);
    final totalBulanLunas =
        allTagihan.where((t) => t.status == StatusTagihan.lunas).length;

    final lg = latestG;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar + name + badge
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white.withValues(alpha: 0.25),
                child: Text(initials,
                    style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(namaResiden,
                              style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                              overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.4)),
                          ),
                          child: Text('Penghuni Aktif',
                              style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$blok – No. $nomorUnit'
                      '${nomorHp != null ? "  •  $nomorHp" : ""}',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.85)),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          // Stat pills
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              StatPill(
                  label: 'TOTAL DIBAYAR',
                  value: formatRupiah(totalDibayar)),
              StatPill(
                  label: 'TOTAL BULAN',
                  value: '$totalBulanLunas Bulan'),
              if (lg != null) ...[
                StatPill(
                    label: 'METODE',
                    value: lg.metode.isNotEmpty ? lg.metode : '-'),
                if (lg.orderId != null)
                  StatPill(
                      label: 'ORDER ID',
                      value: lg.orderId!,
                      mono: true),
                StatPill(
                    label: 'TANGGAL BAYAR',
                    value: lg.tanggalBayar),
                const StatPill(
                    label: 'STATUS PEMBAYARAN',
                    value: '✓ Lunas',
                    valueColor: Color(0xFF86EFAC)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
